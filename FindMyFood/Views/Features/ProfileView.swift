//
//  ProfileView.swift
//  FindMyFood
//
//  Created by Rishik Durvasula on 11/6/24.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            
                VStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                        Text("Name")
                            .font(.headline)
                        Text("@username")
                            .font(.subheadline)
                        
                    HStack {
                        
                        ForEach(0..<3) { _ in
                            
                            VStack {
                                
                                List {
                                    ForEach(0..<3) { _ in
                                        Image(systemName: "person.circle.fill") //gotta change this to the image array per user
                                            .font(.system(size: 100))
                                    }
                                }
                                
                            }
                            
                            
                        }
                        
                    }
                                    
                                    // Add more views as needed
                    }
                    .navigationTitle("Profile")
                    .navigationBarItems(trailing: NavigationLink(destination: EditProfileView()) {
                            Image(systemName: "pencil")
                            .font(.system(size: 20)) // Customize size of the pencil icon
                                })
            
        }
    }
}



//#Preview {
    //ProfileView()
//}
