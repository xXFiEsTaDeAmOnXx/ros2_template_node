// Generic ROS 2 node template (C++).
//
// Dummy "hello world" node showing common building blocks you'll want in
// almost every node: a wall timer, a publisher and a subscriber (each with
// an explicit QoS profile), and parameters. Strip out what you don't need
// and build from here.

#include <chrono>
#include <functional>
#include <memory>
#include <string>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"

using namespace std::chrono_literals;
using std::placeholders::_1;

class __CLASS_NAME__ : public rclcpp::Node
{
public:
  __CLASS_NAME__()
  : Node("__NODE_NAME__"), counter_(0)
  {
    // --- Parameters -------------------------------------------------
    this->declare_parameter("timer_period_sec", 1.0);
    this->declare_parameter("publish_topic", std::string("__NODE_NAME__/hello"));
    this->declare_parameter("subscribe_topic", std::string("__NODE_NAME__/input"));

    timer_period_sec_ = this->get_parameter("timer_period_sec").as_double();
    publish_topic_ = this->get_parameter("publish_topic").as_string();
    subscribe_topic_ = this->get_parameter("subscribe_topic").as_string();

    // --- QoS profile --------------------------------------------------
    // Reliable + volatile is a sensible default for command/data topics.
    // Adjust depth/reliability/durability to match what you're bridging.
    rclcpp::QoS qos(rclcpp::KeepLast(10));
    qos.reliable();
    qos.durability_volatile();

    // --- Publisher ------------------------------------------------------
    publisher_ = this->create_publisher<std_msgs::msg::String>(publish_topic_, qos);

    // --- Subscriber -------------------------------------------------------
    subscription_ = this->create_subscription<std_msgs::msg::String>(
      subscribe_topic_, qos,
      std::bind(&__CLASS_NAME__::subscriber_callback, this, _1));

    // --- Timer ---------------------------------------------------------
    timer_ = this->create_wall_timer(
      std::chrono::duration<double>(timer_period_sec_),
      std::bind(&__CLASS_NAME__::timer_callback, this));

    RCLCPP_INFO(
      this->get_logger(),
      "Started __NODE_NAME__ node (publishing on '%s', listening on '%s', period %.2fs)",
      publish_topic_.c_str(), subscribe_topic_.c_str(), timer_period_sec_);
  }

private:
  void timer_callback()
  {
    auto msg = std_msgs::msg::String();
    msg.data = "hello world " + std::to_string(counter_++);
    RCLCPP_INFO(this->get_logger(), "Publishing: '%s'", msg.data.c_str());
    publisher_->publish(msg);
  }

  void subscriber_callback(const std_msgs::msg::String::SharedPtr msg) const
  {
    RCLCPP_INFO(this->get_logger(), "Received: '%s'", msg->data.c_str());
  }

  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;

  double timer_period_sec_;
  std::string publish_topic_;
  std::string subscribe_topic_;
  size_t counter_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<__CLASS_NAME__>());
  rclcpp::shutdown();
  return 0;
}
