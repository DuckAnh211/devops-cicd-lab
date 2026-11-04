const { test } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');

async function withServer(run) {
  const server = app.listen(0, '127.0.0.1');
  try {
    await new Promise((resolve, reject) => {
      if (server.listening) resolve();
      else { server.once('listening', resolve); server.once('error', reject); }
    });
    const { port } = server.address();
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

test('GET /health returns 200 and status ok', async () => {
  await withServer(async (base) => {
    const response = await fetch(`${base}/health`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok' });
  });
});

test('GET / returns a message', async () => {
  await withServer(async (base) => {
    const response = await fetch(base);
    assert.equal(response.status, 200);
    const data = await response.json();
    assert.equal(typeof data.message, 'string');
    assert.ok(data.message.length > 0);
  });
});
