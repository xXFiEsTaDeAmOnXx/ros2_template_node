#!/usr/bin/env python3
"""Generic ROS 2 node template.

Dummy "hello world" node showing common building blocks you'll want in
almost every node: a timer-driven loop, a publisher and a subscriber
(each with an explicit QoS profile), and parameters. Strip out what you
don't need and build from here.
"""
import rclpy
from rclpy.callback_groups import MutuallyExclusiveCallbackGroup
from rclpy.executors import MultiThreadedExecutor
from rclpy.node import Node
from rclpy.qos import (
    DurabilityPolicy,
    HistoryPolicy,
    QoSProfile,
    ReliabilityPolicy,
)
from std_msgs.msg import String


class __CLASS_NAME__(Node):
    """Dummy hello-world node with a timer, a publisher and a subscriber."""

    def __init__(self):
        super().__init__("__NODE_NAME__")

        # --- Parameters -----------------------------------------------
        self.declare_parameter("timer_period_sec", 1.0)
        self.declare_parameter("publish_topic", "__NODE_NAME__/hello")
        self.declare_parameter("subscribe_topic", "__NODE_NAME__/input")

        self.timer_period_sec = self.get_parameter("timer_period_sec").value
        self.publish_topic = self.get_parameter("publish_topic").value
        self.subscribe_topic = self.get_parameter("subscribe_topic").value

        # --- QoS profiles ------------------------------------------------
        # Reliable + volatile is a sensible default for command/data topics.
        # Adjust depth/reliability/durability to match what you're bridging.
        default_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
            durability=DurabilityPolicy.VOLATILE,
        )

        # --- Callback groups ----------------------------------------------
        # Separate group so the subscriber callback can't block the timer
        # (or vice versa) when using a MultiThreadedExecutor.
        self.callback_group = MutuallyExclusiveCallbackGroup()

        # --- Publisher ---------------------------------------------------
        self.publisher_ = self.create_publisher(
            String, self.publish_topic, default_qos
        )

        # --- Subscriber ----------------------------------------------------
        self.subscription = self.create_subscription(
            String,
            self.subscribe_topic,
            self.subscriber_callback,
            default_qos,
            callback_group=self.callback_group,
        )

        # --- Timer ---------------------------------------------------------
        self._counter = 0
        self.timer = self.create_timer(
            self.timer_period_sec,
            self.timer_callback,
            callback_group=self.callback_group,
        )

        self.get_logger().info(
            f"Started __NODE_NAME__ node "
            f"(publishing on '{self.publish_topic}', "
            f"listening on '{self.subscribe_topic}', "
            f"period {self.timer_period_sec}s)"
        )

    def timer_callback(self):
        """Periodic hello-world publish. Replace with your own logic."""
        msg = String()
        msg.data = f"hello world {self._counter}"
        self._counter += 1

        self.publisher_.publish(msg)
        self.get_logger().info(f"Publishing: '{msg.data}'")

    def subscriber_callback(self, msg: String):
        """Handle incoming messages. Replace with your own logic."""
        self.get_logger().info(f"Received: '{msg.data}'")


def main(args=None):
    rclpy.init(args=args)
    node = __CLASS_NAME__()

    executor = MultiThreadedExecutor(num_threads=2)
    executor.add_node(node)

    try:
        executor.spin()
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
