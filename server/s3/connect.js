import { S3Client, ListBucketsCommand } from '@aws-sdk/client-s3';

const connectAWS = async () => {
    try {
        const s3 = new S3Client({
            region: process.env.AWS_REGION,
            credentials: {
                accessKeyId: process.env.AWS_ACCESS_KEY_ID,
                secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
            },
        });
        const command = new ListBucketsCommand({});
        const response = await s3.send(command);
        console.log('Connected to AWS S3', response.Buckets);
    } catch (err) {
        console.error('AWS connection error:', err);
    }
};

export default connectAWS;
