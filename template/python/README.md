# __PKG_NAME__

TODO: One-paragraph description of what this node does.

## Nodes

*   **__NODE_NAME__:**
    TODO describe what it does.

    Publishes `String` messages on `__NODE_NAME__/hello` and subscribes to
    `__NODE_NAME__/input`, both on a `RELIABLE` / `KEEP_LAST(10)` / `VOLATILE`
    QoS profile.

## Parameters

*   **timer_period_sec** (default: `1.0`): Period of the main timer, in seconds.
*   **publish_topic** (default: `__NODE_NAME__/hello`): Topic the node publishes on.
*   **subscribe_topic** (default: `__NODE_NAME__/input`): Topic the node subscribes to.

## Usage

```bash
docker compose -f docker/docker-compose.yaml up --build
```

Or, without Docker, from a sourced ROS 2 workspace:

```bash
ros2 run __PKG_NAME__ __NODE_NAME__
```
