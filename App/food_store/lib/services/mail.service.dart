import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmail(String receiverEmail, String html, String subject) async {
  final smtpServer = gmail("dkhai0309@gmail.com", "kepu guox wwog cyfs");

  final message = Message()
    ..from = const Address('noreply@gmail.com', 'Yummy Deli noreply')
    ..recipients.add(receiverEmail)
    ..subject = subject
    ..html = html;

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: $sendReport');
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}