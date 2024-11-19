import express from 'express';
import * as dotenv from 'dotenv';
import cors from 'cors';
import https from 'https';
import fs from 'fs';

import connectDB from './mongodb/connect.js';
import connectAWS from './s3/connect.js';
import userRoutes from './routes/userRoutes.js';
import postRoutes from './routes/postRoutes.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

app.use('/api/v1/user', userRoutes);
app.use('/api/v1/post', postRoutes);

app.get('/', async (req, res) => {
    res.send('Testing HTTPS!');
});

// Load self-signed certificate (for testing purposes)
const httpsOptions = {
    key: fs.readFileSync('server.key'), // Path to your private key
    cert: fs.readFileSync('server.cert'), // Path to your certificate
};

const startServer = async () => {
    try {
        // Connect to databases
        connectDB(process.env.MONGODB_URL);
        connectAWS();

        // Start the HTTPS server
        https.createServer(httpsOptions, app).listen(443, () => {
            console.log('HTTPS server started on port 443');
        });

        // Optional: Start HTTP server to redirect to HTTPS
        app.listen(8080, () => {
            console.log('HTTP server started on port 8080');
        });
    } catch (error) {
        console.log(error);
    }
};

startServer();
