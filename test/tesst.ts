import hre from "hardhat";

describe("hardhat-test", () => {
  it("hardhat ethers test", async () => {
    const signers = await hre.ethers.getSigners();
    // bob --> alice : 100 ETH
    const bobWallet = signers[0];
    const aliceWallet = signers[1];
    const tx = {
      from: bobWallet.address,
      to: aliceWallet.address,
      // 1 ETH == 1 * 10^18 wei
      // 100 ETH == 100 * 10^18 wei
      value: hre.ethers.parseEther("100"), // wei
    };
    const txHash = await bobWallet.sendTransaction(tx);
    const receipt = await txHash.wait();
    console.log(await hre.ethers.provider.getTransaction(txHash.hash));
    console.log("------------------------");
    console.log(receipt);
  });
  it("ethers test", async () => {});
});
