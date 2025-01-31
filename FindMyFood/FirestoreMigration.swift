import FirebaseFirestore

struct FirestoreMigration {
    static func migrateOldPosts() async {
        let db = Firestore.firestore()

        do {
            let postsQuerySnapshot = try await db.collection("posts").getDocuments()

            for document in postsQuerySnapshot.documents {
                let data = document.data()

                if let timestampString = data["timestamp"] as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    if let date = formatter.date(from: timestampString) {
                        let timestamp = Timestamp(date: date)

                        try await document.reference.updateData([
                            "timestamp": timestamp
                        ])

                        print("✅ Migrated post: \(document.documentID) with timestamp: \(timestamp)")
                    } else {
                        print("❌ Failed to parse timestamp for post: \(document.documentID)")
                    }
                } else {
                    print("ℹ️ Post \(document.documentID) already has a Timestamp.")
                }
            }

            print("🎉 Migration complete.")
        } catch {
            print("🚨 Error migrating posts: \(error)")
        }
    }
}

