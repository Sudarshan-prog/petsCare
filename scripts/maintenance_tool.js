/**
 * CareBridge Maintenance Tool (Method 2)
 * 
 * This script allows you to perform powerful admin actions that the Firebase Console
 * doesn't support, like bulk-deleting users.
 * 
 * SETUP:
 * 1. Go to Firebase Console -> Project Settings -> Service Accounts.
 * 2. Click "Generate New Private Key" and download the JSON file.
 * 3. Rename it to 'service-account.json' and place it in the same folder as this script.
 * 4. Run: npm install firebase-admin
 * 5. Run: node maintenance_tool.js
 */

const admin = require('firebase-admin');
const path = require('path');

// 1. Initialize admin with service account
const serviceAccountPath = path.join(__dirname, 'service-account.json');

try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin initialized successfully.');
} catch (error) {
    console.error('❌ ERROR: Could not find service-account.json.');
    console.log('Please download it from Firebase Console and place it in: ' + serviceAccountPath);
    process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

/**
 * Bulk Delete All Users
 * DANGER: This is permanent!
 */
async function deleteAllUsers() {
    console.log('--- Starting Bulk User Deletion ---');

    let totalDeleted = 0;

    async function processBatch(nextPageToken) {
        const result = await auth.listUsers(1000, nextPageToken);
        const uids = result.users.map(user => user.uid);

        if (uids.length > 0) {
            // Bulk delete from Auth
            await auth.deleteUsers(uids);
            console.log(`🗑️ Deleted ${uids.length} users from Authentication.`);
            totalDeleted += uids.length;

            // Note: This script only deletes from AUTH. 
            // Firestore data should be deleted using the "Clear Collection" 
            // feature in Firestore UI, which you've already seen.
        }

        if (result.pageToken) {
            await processBatch(result.pageToken);
        }
    }

    try {
        await processBatch();
        console.log(`\n✨ SUCCESS: Total users deleted: ${totalDeleted}`);
        console.log('The database is now clean.');
    } catch (error) {
        console.error('❌ ERROR during deletion:', error);
    }
}

// EXECUTE
deleteAllUsers();
