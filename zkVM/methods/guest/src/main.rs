// This guest code will run inside the zkVM and perform the private computation. 
use risc0_zkvm::guest::env;

fn main() {
    // Thought Process:
    // I want to prove someone is within a valid age range without revealing their actual age
    // Private Input: Three u32 values — age, min_age, and max_age
    // Computation: age >= min_age && age <= max_age (range check)
    // Public Output: The verifier should see true or false
    // Control Flow: Single boolean expression so no if/else needed
    // Data Type: Scalar (u32) for all three inputs, bool for output

    // read the input
    let age: u32 = env::read();
    let min_age: u32 = env::read();
    let max_age: u32 = env::read();

    // TODO: do something with the input
    // check if age is within the valid range
    let is_adult: bool = age >= min_age && age <= max_age;

    // write public output to the journal
    env::commit(&is_adult);
}
