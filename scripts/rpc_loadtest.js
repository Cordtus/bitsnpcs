const axios = require('axios');

const rpcAddress = '<your_rpc<here>'; // Replace with your API endpoint
const initialRequestsPerSecond = 1; // Starting rate of requests per second
const maxRampUpStages = 10; // Maximum number of stages to try ramping up
const rampUpFactor = 2; // Factor to increase the request rate by each stage
const testDuration = 5000; // Duration for each stage in milliseconds
const runMaxOnly = process.argv.includes('--max'); // Option to run only the max stage

let currentStage = 0;
let currentRate = initialRequestsPerSecond;

async function getLatestBlockHeight(rpcAddress) {
  try {
    const response = await axios.get(`${rpcAddress}/status`);
    if (response.data && response.data.result && response.data.result.sync_info && response.data.result.sync_info.latest_block_height) {
      const height = parseInt(response.data.result.sync_info.latest_block_height, 10);
      return height;
    } else {
      throw new Error('Unexpected response format');
    }
  } catch (error) {
    console.error('Failed to get latest block height:', error.message);
    process.exit(1);
  }
}

async function sendBlockRequest(rpcAddress, height) {
  const start = Date.now();
  try {
    await axios.get(`${rpcAddress}/block?height=${height}`);
    const end = Date.now();
    return { success: true, responseTime: end - start };
  } catch (error) {
    const end = Date.now();
    return { success: false, responseTime: end - start, error: error.message };
  }
}

async function runTest() {
  console.log(`Starting server performance test...`);

  // Stage 0: Get latest block height
  console.log(`
--- Stage 0: Fetching latest block height ---`);
  const startStage0 = Date.now();
  const latestHeight = await getLatestBlockHeight(rpcAddress);
  const endStage0 = Date.now();
  console.log(`Latest block height: ${latestHeight}, Time taken: ${endStage0 - startStage0} ms`);

  if (runMaxOnly) {
    currentStage = maxRampUpStages - 1;
    currentRate = 5 * Math.pow(rampUpFactor, currentStage - 1);
    console.log(`
--- Running only max stage: Fetching ${currentRate} blocks ---`);
    await runStage(rpcAddress, latestHeight, currentRate);
  } else {
    while (currentStage < maxRampUpStages) {
      const blocksToFetch = 5 * Math.pow(rampUpFactor, currentStage);
      console.log(`
--- Stage ${currentStage + 1}: Fetching ${blocksToFetch} blocks ---`);
      await runStage(rpcAddress, latestHeight, blocksToFetch);
      currentStage++;
    }
  }
  console.log(`Test completed.`);
}

async function runStage(rpcAddress, latestHeight, blocksToFetch) {
  let successCount = 0;
  let failureCount = 0;
  let totalResponseTime = 0;

  // Send block requests concurrently for the specified number of blocks
  const requests = [];
  for (let i = 0; i < blocksToFetch; i++) {
    const height = latestHeight - i;
    requests.push(sendBlockRequest(rpcAddress, height));
  }

  // Wait for all requests to finish
  const results = await Promise.all(requests);

  // Analyze the results
  results.forEach(result => {
    if (result.success) {
      successCount++;
      totalResponseTime += result.responseTime;
    } else {
      failureCount++;
    }
  });

  const averageResponseTime = successCount > 0 ? totalResponseTime / successCount : 0;

  console.log(`Success: ${successCount}, Failures: ${failureCount}, Average Response Time: ${averageResponseTime.toFixed(2)} ms`);
}

runTest().catch(error => {
  console.error('An error occurred during the test:', error);
});
