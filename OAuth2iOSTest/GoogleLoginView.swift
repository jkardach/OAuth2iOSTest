//
//  GoogleLoginView.swift
//  OAuth2iOSTest
//
//  Created by jim kardach on 8/29/23.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Combine



struct SheetData: Codable {
    let range: String
    let majorDimension: String
    let values: [[String]]?
}

class User {
    var name: String = "Nobody"
    var pictureUrl: URL = URL(string: "https://randomfox.ca/images/70.jpg")!
    var accessToken: String {
        get {
            return GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString ?? ""
        }
    }
}


struct GoogleLoginView: View {
    
    var loggedIn = User()
    
    let sheetID = "1FDd6FOJjmQKczdELlSdU3PeV_xfsarfVCjxrw0eqzvs"
    let api_key = "AIzaSyBVMly-nKAxFv9xuMYu_SFSDyaB6PJdti0"
    
    var body: some View {
        VStack {
            
            Image("SignIn")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: getRect().height / 2)
                .padding(.horizontal, 20)
                .offset(y: -10)
            // background circle
            .background(
                Circle()
                    .fill(Color(.cyan))       // apply Scale
                    .scaleEffect(2, anchor: .bottom)
                    .offset(y: 40)
            )
            HStack {
                AsyncImage(url: loggedIn.pictureUrl) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 40)
                .background(Color.gray)
                .clipShape(Circle())
                    .frame(width: 40, height: 40)
                    .background(Color.gray)
                    .clipShape(Circle())
                    .padding(.all, 10)
                Text(loggedIn.name)
                    .padding(.horizontal, 5)
                Spacer()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray, lineWidth: 1)
            )
            .padding(.horizontal, 5)

            GoogleSignInButton(action: handleSignInButton)
                .padding(.top, 20)
            Spacer()
            Button {
                Task {
                    await readSheet()
                }
            } label: {
             Text("Read Sheet")
                .foregroundColor(.red)
            }
            Spacer()
            Button {
                Task {
                    await writeSheet()
                }
            } label: {
             Text("Write Sheet")
                .foregroundColor(.blue)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // handle Login
    func handleSignInButton() {
        let rootViewController = ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController)!
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController) { signInResult, error in
                guard let signInResult = signInResult else {
                    print("Not logged in")
                    return
                }
                let user = signInResult.user
                // get user pictureURL and name
                loggedIn.pictureUrl = (user.profile?.imageURL(withDimension: 50))!
                loggedIn.name = user.profile?.name ?? "Unknown"
                
                guard let currentUser = GIDSignIn.sharedInstance.currentUser else { return }
                let spreadsheetsScope = "https://www.googleapis.com/auth/spreadsheets"
                let grantedScopes = user.grantedScopes
                if grantedScopes == nil || !grantedScopes!.contains(spreadsheetsScope) {
                    currentUser.addScopes([spreadsheetsScope], presenting: rootViewController) { signInResult, error in
                        guard error == nil else { return }
                        // guard let signInResult = signInResult else { return }
                        // Check if the user granted access to the scopes you requested.
                    }
                }
                
                currentUser.refreshTokensIfNeeded { user, error in
                    guard error == nil else { return }
                    guard let user = user else { return }
                }
            }
    }
    
    func readSheet() async {
        struct SheetData: Codable {
            let range: String
            let majorDimension: String
            let values: [[String]]
        }
        var sheetData: SheetData
        print("Access Token: \(loggedIn.accessToken)")
        
        let baseURL = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetID)/values/Sheet2!A1:J10"
        let readURL = baseURL + "?access_token=" + loggedIn.accessToken + "&majorDimension=ROWS" + "&key=" + api_key
        
        guard let url = URL(string: readURL) else { return }
        
        let request = URLRequest(url: url)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // decode data
            let decoder = JSONDecoder()
            sheetData = try decoder.decode(SheetData.self, from: data)
            print("A1:J10 data: \(sheetData)")
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    func writeSheet() async {
        
        let range = "Sheet1!A1:D5"
        let baseURL = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetID)/values/\(range)"
        let valueInputOption = "?valueInputOption=USER_ENTERED"
        let accessToken = "&access_token=\(loggedIn.accessToken)"
        let apiKey = "&key=\(api_key)"
        let postURL = baseURL + valueInputOption + accessToken + api_key
        
        // create URL
        guard let url = URL(string: postURL) else {
            print("Invalid URL")
            return
        }
        
        // create a codable object to write to spreadsheet
        let sheetData = SheetData(range: range, majorDimension: "ROWS",
                                  values: [
                                    ["Item", "Cost", "Stocked", "Ship Date"],
                                    ["Wheel", "$20.50", "4", "3/1/2016"],
                                    ["Door", "$15", "2", "3/15/2016"],
                                    ["Engine", "$100", "1", "3/20/2016"],
                                    ["Totals", "=SUM(B2:B4)", "=SUM(C2:C4)", "=MAX(D2:D4)"]
                                  ])

        // convert to JSON
        guard let jsonData = try? JSONEncoder().encode(sheetData) else {
            print("Failed to encode data")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        
        do {
            let (data, meta) = try await URLSession.shared.upload(for: request, from: jsonData)
            // handle the result
            let str = String(decoding: jsonData, as: UTF8.self)
            print("response data: \n\(str)\n\n")
            print("\nmeta from post: \n\(meta)")
        } catch {
            print("Post data failed.")
        }
    }
}



struct GoogleLoginView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleLoginView()
    }
}

// Extending View to get Screen Bounds
extension View {
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
}

