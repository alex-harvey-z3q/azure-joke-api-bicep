const express = require('express');
const os = require('os');

const app = express();
const port = process.env.PORT || 3000;

const appName = process.env.APP_NAME || 'azure-joke-api-bicep';
const appEnvironment = process.env.APP_ENV || 'local';

const jokes = [
  'Why do JavaScript developers wear glasses? Because they do not C#.',
  'I told my Azure App Service a joke. It scaled out laughing.',
  'Why did the function break up with the callback? It wanted promises.',
  'There are only 10 kinds of people: those who understand binary and those who do not.',
  'Why was the API calm during the interview? It had good endpoints.'
];

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.get('/joke', (_req, res) => {
  const joke = jokes[Math.floor(Math.random() * jokes.length)];
  res.json({ joke });
});

app.get('/metadata', (_req, res) => {
  res.json({
    appName,
    environment: appEnvironment,
    hostname: process.env.WEBSITE_HOSTNAME || os.hostname(),
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`${appName} listening on port ${port}`);
});
