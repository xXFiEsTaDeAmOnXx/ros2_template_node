ARG BASE_IMAGE=ros:jazzy
FROM $BASE_IMAGE AS base

ENV ROS_WS=/root/ros2_ws
COPY __PKG_NAME__ ${ROS_WS}/src/__PKG_NAME__

WORKDIR ${ROS_WS}

RUN . /opt/ros/jazzy/setup.sh && \
    colcon build --symlink-install
