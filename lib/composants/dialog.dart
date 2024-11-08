import 'package:flutter/material.dart';

class MyRadio extends StatefulWidget {
  const MyRadio({
    super.key,
  });

  @override
  State<MyRadio> createState() => _MyRadioState();
}

List<String> options = ["+", "-"];
class _MyRadioState extends State<MyRadio> {
  
  String currentOption = options[0];
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ListTile(
          title: const Text("+"),
          leading: Radio(
            value: options[0], 
            groupValue: currentOption,
             onChanged: (value) {
              setState(() {
                currentOption = value.toString();
              });
             }),
        ),
        ListTile(
          title: const Text("-"),
          leading: Radio(
            value: options[1], 
            groupValue: currentOption,
             onChanged: (value) {
              setState(() {
                currentOption = value.toString();
              });
             }),
        ),
      ],
    );
  }
}