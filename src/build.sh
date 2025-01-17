#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COMPONENTS_DIR="$SCRIPT_DIR/components"
TESTS_DIR="$SCRIPT_DIR/tests"
LAYERS_DIR="$COMPONENTS_DIR/layers"
TEST_DIR="$TESTS_DIR/layers_testbench"
BUILD_DIR="$SCRIPT_DIR/build"
DUMP_DIR="$TESTS_DIR/dump"

mkdir -p $BUILD_DIR
mkdir -p $DUMP_DIR

run_layer_tests() {
    echo "Running layer tests..."
    echo "Looking for tests in: $TEST_DIR"
    echo "Looking for implementations in: $LAYERS_DIR"
    echo "Build outputs will go to: $BUILD_DIR"
    echo "VCD dumps will go to: $DUMP_DIR"
    echo ""
    
    if [ ! -d "$TEST_DIR" ]; then
        echo "Error: Test directory not found at $TEST_DIR"
        exit 1
    fi
    
    for test_file in $TEST_DIR/*_tb.v; do
        if [ -f "$test_file" ]; then
            test_name=$(basename "$test_file" _tb.v)
            echo "Found test: $test_file"
            echo "Looking for implementation: $LAYERS_DIR/${test_name}.v"
            
            if [ ! -f "$LAYERS_DIR/${test_name}.v" ]; then
                echo "Warning: No implementation found for ${test_name}.v"
                continue
            fi
            
            export VCD_DUMP_PATH="$DUMP_DIR/${test_name}_tb.vcd"
            
            echo "Compiling: iverilog -g2012 -o $BUILD_DIR/${test_name}_test $test_file $LAYERS_DIR/${test_name}.v"
            iverilog -g2012 -o "$BUILD_DIR/${test_name}_test" \
                    -DVCD_DUMP_PATH="\"$DUMP_DIR/${test_name}_tb.vcd\"" \
                    "$test_file" \
                    "$LAYERS_DIR/${test_name}.v"
            
            if [ $? -eq 0 ]; then
                echo "Compilation successful for $test_name"
                echo "Running: vvp $BUILD_DIR/${test_name}_test"
                vvp "$BUILD_DIR/${test_name}_test"
            else
                echo "Compilation failed for $test_name"
            fi
            echo "----------------------------------------"
        fi
    done
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 [--test]"
    echo "  --test    Run all layer tests"
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            echo "#### RUNNING TESTS ####"
            echo ""
            run_layer_tests
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done