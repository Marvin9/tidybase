import {
  AutoScalingClient,
  DescribeAutoScalingGroupsCommand,
  UpdateAutoScalingGroupCommand,
} from "@aws-sdk/client-auto-scaling";
import {
  ElasticLoadBalancingV2Client as ELBv2Client,
  DeregisterTargetsCommand,
  RegisterTargetsCommand,
  DescribeTargetHealthCommand,
} from "@aws-sdk/client-elastic-load-balancing-v2";

const autoScalingClient = new AutoScalingClient({ region: "us-east-1" });
const elbv2Client = new ELBv2Client({ region: "us-east-1" });

const BigAutoScalingName = process.env.BIG_AUTO_SCALING_NAME;
const TinyAutoScalingName = process.env.TINY_AUTO_SCALING_NAME;
const TargetGroupArn = process.env.TARGET_GROUP_ARN;

const checkInstancesHealth = async (autoScalingGroupName) => {
  while (true) {
    const describeCommand = new DescribeAutoScalingGroupsCommand({
      AutoScalingGroupNames: [autoScalingGroupName],
    });

    const data = await autoScalingClient.send(describeCommand);
    const autoScalingGroup = data.AutoScalingGroups[0];

    if (!autoScalingGroup) {
      throw new Error(`Auto Scaling Group ${autoScalingGroupName} not found`);
    }

    const unhealthyInstances = autoScalingGroup.Instances.filter(
      (instance) =>
        instance.HealthStatus !== "Healthy" ||
        instance.LifecycleState !== "InService"
    );

    if (
      autoScalingGroup.Instances?.length > 0 &&
      unhealthyInstances.length === 0
    ) {
      return true;
    }

    // Wait for a few seconds before checking again
    await new Promise((resolve) => setTimeout(resolve, 5000));
  }
};

const deregisterAsgFromTargetGroup = async (asgName, targetGroupArn) => {
  const instances = await getAsgInstances(asgName);
  if (instances.length === 0) {
    console.log(`No instances found in Auto Scaling Group ${asgName}`);
    return;
  }

  const targets = instances.map((instance) => ({ Id: instance }));
  await elbv2Client.send(
    new DeregisterTargetsCommand({
      TargetGroupArn: targetGroupArn,
      Targets: targets,
    })
  );
  console.log(`Deregistered instances from target group ${targetGroupArn}`);
};

const registerAsgToTargetGroup = async (asgName, targetGroupArn) => {
  const instances = await getAsgInstances(asgName);
  if (instances.length === 0) {
    console.log(`No instances found in Auto Scaling Group ${asgName}`);
    return;
  }

  const targets = instances.map((instance) => ({ Id: instance }));
  await elbv2Client.send(
    new RegisterTargetsCommand({
      TargetGroupArn: targetGroupArn,
      Targets: targets,
    })
  );
  console.log(`Registered instances to target group ${targetGroupArn}`);
};

const getAsgInstances = async (asgName) => {
  const params = {
    AutoScalingGroupNames: [asgName],
  };

  const response = await autoScalingClient.send(
    new DescribeAutoScalingGroupsCommand(params)
  );
  const asg = response.AutoScalingGroups[0];

  if (!asg) {
    throw new Error(`Auto Scaling Group ${asgName} not found`);
  }

  return asg.Instances.map((instance) => instance.InstanceId);
};

const waitForHealthyInstances = async (asgName, targetGroupArn) => {
  const instances = await getAsgInstances(asgName);

  const checkHealth = async () => {
    const { TargetHealthDescriptions } = await elbv2Client.send(
      new DescribeTargetHealthCommand({
        TargetGroupArn: targetGroupArn,
      })
    );

    const healthyInstances = TargetHealthDescriptions.filter(
      (description) =>
        description.TargetHealth.State === "healthy" &&
        instances.includes(description.Target.Id)
    );

    return healthyInstances.length === instances.length;
  };

  // Wait for instances to become healthy
  let attempts = 0;
  const maxAttempts = 30;
  const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  while (attempts < maxAttempts) {
    if (await checkHealth()) {
      console.log(
        `All instances in Auto Scaling Group ${asgName} are healthy.`
      );
      return;
    }
    console.log(
      `Waiting for instances in Auto Scaling Group ${asgName} to become healthy...`
    );
    attempts++;
    await delay(10000); // Wait for 10 seconds before checking again
  }

  throw new Error(
    `Instances in Auto Scaling Group ${asgName} did not become healthy within the expected time.`
  );
};

export const handler = async (event) => {
  try {
    // Update the Auto Scaling Group
    await autoScalingClient.send(
      new UpdateAutoScalingGroupCommand({
        AutoScalingGroupName: TinyAutoScalingName,
        MinSize: 1,
        MaxSize: 1,
        DesiredCapacity: 1,
      })
    );

    // Wait until all instances in the group are healthy
    await checkInstancesHealth(TinyAutoScalingName);

    await registerAsgToTargetGroup(TinyAutoScalingName, TargetGroupArn);

    await waitForHealthyInstances(TinyAutoScalingName, TargetGroupArn);

    await deregisterAsgFromTargetGroup(BigAutoScalingName, TargetGroupArn);

    await autoScalingClient.send(
      new UpdateAutoScalingGroupCommand({
        AutoScalingGroupName: BigAutoScalingName,
        MinSize: 0,
        MaxSize: 0,
        DesiredCapacity: 0,
      })
    );

    return {
      statusCode: 200,
      body: JSON.stringify(
        "Auto Scaling Group updated, instances are healthy, and target group updated"
      ),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify("Error: " + error.message),
    };
  }
};
