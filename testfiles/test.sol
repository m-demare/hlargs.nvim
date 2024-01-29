contract ArgumentHighlightingTest {

    uint256 public value;

    constructor(uint256 initialValue) {
        value = initialValue;
    }

    function updateValue(uint256 newValue) external {
        value = newValue;
    }

    function multiplyAndUpdate(uint256 factor) external {
        value *= factor;
    }

    function addTwoValues(uint256 a, uint256 b) external view returns (uint256) {
        return a + b;
    }
}

