// lib/components/movigo_alert_dialog.dart
import 'package:flutter/material.dart';
import 'package:movigo_frontend/utils/colors.dart';
import 'package:movigo_frontend/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class MovigoAlertDialog extends StatelessWidget {
  final Key? key;

  const MovigoAlertDialog({this.key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(movigoBottomSheetRadius)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Imagen del conductor
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  'assets/images/driver_avatar.jpeg',
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nombre del Conductor',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: movigoDarkColor),
                  ),
                  SizedBox(
                    height: 16,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, index) => Icon(
                          index == 4 ? Icons.star_border : Icons.star,
                          color: movigoSecondaryColor,
                          size: 14),
                      itemCount: 5,
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                  SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: 'ST3571 ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                            text: '- Toyota Vios',
                            style: TextStyle(
                                color: movigoGreyColor,
                                fontSize: 10,
                                fontWeight: FontWeight.normal)),
                      ],
                    ),
                  )
                ],
              ),

              Container(
                decoration: BoxDecoration(
                    color: movigoSecondaryColor,
                    borderRadius: BorderRadius.circular(100)),
                child: IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final Uri url = Uri(scheme: 'tel', path: '1234567');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      print('Could not launch $url');
                    }
                  },
                ),
              )
            ],
          ),
          Divider(height: 20),
          Text(
            'Tu conductor ha llegado. Por favor prepárate en los próximos 5 minutos.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: movigoPrimaryColor,
              minimumSize: Size(MediaQuery.of(context).size.width, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(movigoButtonRadius)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Aquí puedes navegar a la pantalla de respuesta
            },
            child: Text('RESPONDER',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
