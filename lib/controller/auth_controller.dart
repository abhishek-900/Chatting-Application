import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../helperfunctions.dart';
class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = new GoogleSignIn();

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      AuthResult result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;
      DocumentSnapshot details = await Firestore.instance.collection('users')
          .document(user.uid).get();
     // print("${details.data['']}");
      UserUpdateInfo userUpdateInfo = UserUpdateInfo();
      userUpdateInfo.displayName = details.data["nickname"];
      userUpdateInfo.photoUrl = details.data["photoUrl"];
      user.updateProfile(userUpdateInfo);
      await user.reload();
      Firestore.instance.collection('users').document(user.uid).updateData({'connectionStatus' : 'Online'});
          await HelperFunctions.saveUserLoggedInSharedPreference(true);
          await HelperFunctions.saveUserEmailSharedPreference(user.email); //prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserIdSharedPreference(user.uid); //prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserNameSharedPreference(details.data["nickname"]); //prefs.setString('nickname', currentUser.displayName);
          await HelperFunctions.saveUserPhotoUrlSharedPreference(details.data["photoUrl"]);
          await HelperFunctions.saveUserAboutMeSharedPreference(details.data['aboutMe']);

      print("sign in method mein kya ho rh hi??....");
      print("{${user.uid} --> ${user.displayName} --> ${user.email} --> ${user.photoUrl}}");

      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<FirebaseUser> signUpWithEmailAndPassword(String email, String password, String nickname) async {
      AuthResult authResult = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
     FirebaseUser firebaseUser = authResult.user;
      if(firebaseUser != null){
        print("yani user to h bhyi....");
      final QuerySnapshot result =
      await Firestore.instance.collection('users').where(
          'id', isEqualTo: firebaseUser.uid).getDocuments();
      print("Query snapshot result = $result");
      final List<DocumentSnapshot> documents = result.documents;
      print("doc ln: == ${documents.length} documents");
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance.collection('users')
            .document(firebaseUser.uid)
            .setData({
          'email': firebaseUser.email,
          'nickname': nickname,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid,
          'createdAt': DateTime
              .now()
              .millisecondsSinceEpoch
              .toString(),
          'chattingWith': '',
          'connectionStatus' : 'Online'
        });

        await HelperFunctions.saveUserLoggedInSharedPreference(true);
        await HelperFunctions.saveUserEmailSharedPreference(firebaseUser.email); //prefs.setString('id', currentUser.uid);
        await HelperFunctions.saveUserIdSharedPreference(firebaseUser.uid); //prefs.setString('id', currentUser.uid);
        await HelperFunctions.saveUserNameSharedPreference(nickname); //prefs.setString('nickname', currentUser.displayName);
        await HelperFunctions.saveUserPhotoUrlSharedPreference(firebaseUser.photoUrl);
      }else {
        // Write data to local
        await HelperFunctions.saveUserLoggedInSharedPreference(true);
        await HelperFunctions.saveUserEmailSharedPreference(documents[0]['email']); //prefs.setString('id', currentUser.uid);
        await HelperFunctions.saveUserIdSharedPreference(documents[0]['id']); //prefs.setString('id', currentUser.uid);
        await HelperFunctions.saveUserNameSharedPreference(documents[0]['nickname']); //prefs.setString('nickname', currentUser.displayName);
        await HelperFunctions.saveUserPhotoUrlSharedPreference(documents[0]['photoUrl']); //prefs.setString('photoUrl', currentUser.photoUrl);
        await HelperFunctions.saveUserAboutMeSharedPreference(documents[0]['aboutMe']);
      }
      return firebaseUser;
    }else {
      return null;
    }
  }

  Future resetPass(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<FirebaseUser> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount googleSignInAccount =
    await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);
      AuthResult authResult = await _auth.signInWithCredential(credential);

      FirebaseUser firebaseUser = authResult.user;
      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result =
        await Firestore.instance.collection('users').where(
            'id', isEqualTo: firebaseUser.uid).getDocuments();
        final List<DocumentSnapshot> documents = result.documents;
        if (documents.length == 0) {
          // Update data to server if new user
          Firestore.instance.collection('users')
              .document(firebaseUser.uid)
              .setData({
            'email': firebaseUser.email,
            'nickname': firebaseUser.displayName,
            'photoUrl': firebaseUser.photoUrl,
            'id': firebaseUser.uid,
            'createdAt': DateTime
                .now()
                .millisecondsSinceEpoch
                .toString(),
            'chattingWith': "",
            'connectionStatus' : "Online"
          });
          await HelperFunctions.saveUserLoggedInSharedPreference(true);
          await HelperFunctions.saveUserEmailSharedPreference(
              firebaseUser.email); //prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserIdSharedPreference(
              firebaseUser.uid); //prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserNameSharedPreference(firebaseUser
              .displayName); //prefs.setString('nickname', currentUser.displayName);
          await HelperFunctions.saveUserPhotoUrlSharedPreference(firebaseUser
              .photoUrl); //prefs.setString('photoUrl', currentUser.photoUrl);
        } else {
          // Write data to local
          await HelperFunctions.saveUserLoggedInSharedPreference(true);
          await HelperFunctions.saveUserEmailSharedPreference(
              documents[0]['email']); //prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserIdSharedPreference(
              documents[0]['id']); //prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserNameSharedPreference(
              documents[0]['nickname']); //prefs.setString('nickname', currentUser.displayName);
          await HelperFunctions.saveUserPhotoUrlSharedPreference(
              documents[0]['photoUrl']); //prefs.setString('photoUrl', currentUser.photoUrl);
          await HelperFunctions.saveUserAboutMeSharedPreference(
              documents[0]['aboutMe']);
        }
        return firebaseUser;
      }else{
        return null;
      }
  }

  Future signOut() async {
    try {
      String id = await HelperFunctions.getUserIdSharedPreference();
      await _auth.signOut();
      await _googleSignIn.signOut();
      Firestore.instance.collection('users').document(id).updateData({'connectionStatus' : 'Offline'});
      await HelperFunctions.saveUserLoggedInSharedPreference(null);
      await HelperFunctions.saveUserAboutMeSharedPreference(null);
      await HelperFunctions.saveUserEmailSharedPreference(null);
      await HelperFunctions.saveUserIdSharedPreference(null);
      await HelperFunctions.saveUserNameSharedPreference(null);
      await HelperFunctions.saveUserPhotoUrlSharedPreference(null);

    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  deleteAccount() async {
    try {
      FirebaseUser user = await _auth.currentUser();
      bool ans = await _googleSignIn.isSignedIn();
      if (ans) {
        _googleSignIn.disconnect();
      }
      user.delete();
    }catch(e){
      print("delete error :- "+ e.toString());

    }
  }

  Stream<DocumentSnapshot> getConnectionStatus({@required peerId}) => Firestore.instance.collection('users').document(peerId).snapshots();
}
