#!/usr/bin/env bash
#
# create_package.sh
#
# Generates a new ROS 2 (ament_python) package from the template/ directory
# next to this script: package.xml, setup.py/.cfg, a dummy node with a
# timer + QoS'd publisher/subscriber, ament test boilerplate, a Dockerfile
# and docker-compose service, and a README — all with the names you give
# below.
#
# Usage:
#   ./create_package.sh [output_dir]
#
# output_dir defaults to the current directory. The new package is created
# as <output_dir>/<pkg_name>/.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/template"
OUTPUT_DIR="${1:-$(pwd)}"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: template directory not found at '$TEMPLATE_DIR'." >&2
    echo "Keep create_package.sh next to the template/ folder." >&2
    exit 1
fi

# --- helpers ----------------------------------------------------------

# Validate a ROS 2 identifier: lowercase letters, digits, underscores;
# must start with a letter.
is_valid_ros_identifier() {
    [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

# snake_case -> PascalCase (e.g. wait_for_gripper_force -> WaitForGripperForce)
to_pascal_case() {
    local input="$1"
    local IFS='_'
    local part result=""
    for part in $input; do
        result+="$(tr '[:lower:]' '[:upper:]' <<<"${part:0:1}")${part:1}"
    done
    echo "$result"
}

# Escape a string for safe use as the replacement side of `sed s/.../.../`
sed_escape_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

# --- prompts ------------------------------------------------------------

read -rp "Package name (snake_case, e.g. my_robot_node): " PKG_NAME
while ! is_valid_ros_identifier "$PKG_NAME"; do
    echo "Invalid package name. Use lowercase letters, digits and underscores, starting with a letter."
    read -rp "Package name (snake_case, e.g. my_robot_node): " PKG_NAME
done

read -rp "Executable / node name [default: ${PKG_NAME}]: " NODE_NAME
NODE_NAME="${NODE_NAME:-$PKG_NAME}"
while ! is_valid_ros_identifier "$NODE_NAME"; do
    echo "Invalid node name. Use lowercase letters, digits and underscores, starting with a letter."
    read -rp "Executable / node name [default: ${PKG_NAME}]: " NODE_NAME
    NODE_NAME="${NODE_NAME:-$PKG_NAME}"
done

read -rp "Author name: " AUTHOR_NAME
while [ -z "$AUTHOR_NAME" ]; do
    echo "Author name cannot be empty."
    read -rp "Author name: " AUTHOR_NAME
done

read -rp "Author email [default: ${PKG_NAME}@todo.todo]: " AUTHOR_EMAIL
AUTHOR_EMAIL="${AUTHOR_EMAIL:-${PKG_NAME}@todo.todo}"

CLASS_NAME="$(to_pascal_case "$NODE_NAME")"
TARGET_DIR="${OUTPUT_DIR%/}/${PKG_NAME}"

if [ -e "$TARGET_DIR" ]; then
    echo "Error: '$TARGET_DIR' already exists. Choose a different package name or output directory." >&2
    exit 1
fi

echo
echo "Generating package:"
echo "  Package name : $PKG_NAME"
echo "  Node name    : $NODE_NAME"
echo "  Class name   : $CLASS_NAME"
echo "  Author       : $AUTHOR_NAME <$AUTHOR_EMAIL>"
echo "  Target dir   : $TARGET_DIR"
echo

# --- copy template --------------------------------------------------------

cp -r "$TEMPLATE_DIR" "$TARGET_DIR"

# --- rename paths containing placeholders (deepest first) -----------------
#
# The full path list is materialized up front (mapfile) rather than piped
# straight from `find`, since renaming directories while `find` is still
# traversing the same tree can race and make later paths stale.

mapfile -d '' -t all_paths < <(find "$TARGET_DIR" -depth -print0)
for path in "${all_paths[@]}"; do
    dir="$(dirname "$path")"
    base="$(basename "$path")"
    newbase="${base//__PKG_NAME__/$PKG_NAME}"
    newbase="${newbase//__NODE_NAME__/$NODE_NAME}"
    if [ "$base" != "$newbase" ]; then
        mv "$dir/$base" "$dir/$newbase"
    fi
done

# --- substitute placeholders inside file contents --------------------------

PKG_NAME_ESC="$(sed_escape_replacement "$PKG_NAME")"
NODE_NAME_ESC="$(sed_escape_replacement "$NODE_NAME")"
CLASS_NAME_ESC="$(sed_escape_replacement "$CLASS_NAME")"
AUTHOR_NAME_ESC="$(sed_escape_replacement "$AUTHOR_NAME")"
AUTHOR_EMAIL_ESC="$(sed_escape_replacement "$AUTHOR_EMAIL")"

find "$TARGET_DIR" -type f -print0 | xargs -0 sed -i \
    -e "s/__PKG_NAME__/${PKG_NAME_ESC}/g" \
    -e "s/__NODE_NAME__/${NODE_NAME_ESC}/g" \
    -e "s/__CLASS_NAME__/${CLASS_NAME_ESC}/g" \
    -e "s/__AUTHOR_NAME__/${AUTHOR_NAME_ESC}/g" \
    -e "s/__AUTHOR_EMAIL__/${AUTHOR_EMAIL_ESC}/g"

chmod +x "${TARGET_DIR}/${PKG_NAME}/${PKG_NAME}/${NODE_NAME}.py"

echo "Done. New package created at: $TARGET_DIR"
echo
echo "Next steps:"
echo "  cd $TARGET_DIR"
echo "  docker compose -f docker/docker-compose.yaml up --build"
echo
echo "Or, in a sourced ROS 2 workspace:"
echo "  colcon build --symlink-install --packages-select $PKG_NAME"
echo "  ros2 run $PKG_NAME $NODE_NAME"
