import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId = '';
  bool codeSent = false;
  bool loading = false;

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMessage('Enter your phone number');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,

        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            loading = false;
          });

          showMessage(e.message ?? 'Verification failed');
        },

        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            codeSent = true;
            loading = false;
          });

          showMessage('OTP sent by SMS 📱');
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        loading = false;
      });

      showMessage('Error: $e');
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      showMessage('Enter the OTP code');
      return;
    }

    if (verificationId.isEmpty) {
      showMessage('Please request an OTP first');
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      showMessage('OTP verified successfully ✅');
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Invalid OTP');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+213XXXXXXXXX',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loading ? null : sendOtp,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Send OTP'),
            ),

            const SizedBox(height: 30),

            if (codeSent) ...[
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: verifyOtp,
                child: const Text('Verify OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}