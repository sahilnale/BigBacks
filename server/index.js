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

// Define API routes
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/post', postRoutes);

// Default route
app.get('/', async (req, res) => {
    res.send('Welcome to the HTTPS-secured API!');
});

// Redirect HTTP to HTTPS (middleware for HTTP server)
const redirectToHttps = (req, res) => {
    const host = req.headers.host.replace(/:\d+/, ''); // Remove port if present
    res.redirect(`https://${host}${req.url}`);
};

const startServer = async () => {
    try {
        // Connect to MongoDB and AWS S3
        console.log('Connecting to databases...');
        await connectDB(process.env.MONGODB_URL);
        connectAWS();
        console.log('Databases connected successfully.');

        // Load HTTPS certificate and key
        const httpsOptions = {
            key: fs.readFileSync(process.env.HTTPS_KEY_PATH || 'server.key'),
            cert: fs.readFileSync(process.env.HTTPS_CERT_PATH || 'server.cert'),
        };

        // Start the HTTPS server
        https.createServer(httpsOptions, app).listen(process.env.HTTPS_PORT || 443, () => {
            console.log(`HTTPS server running on port ${process.env.HTTPS_PORT || 443}`);
        });

        // Start the HTTP server to redirect to HTTPS
        const httpApp = express();
        httpApp.use('*', redirectToHttps); // Redirect all HTTP traffic
        httpApp.listen(process.env.HTTP_PORT || 80, () => {
            console.log(`HTTP server running on port ${process.env.HTTP_PORT || 80}`);
        });
    } catch (error) {
        console.error('Error starting the server:', error.message);
    }
};

startServer();
