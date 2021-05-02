
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isearch/map_screen.dart';
import 'package:splash_screen_view/SplashScreenView.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main(){
  runApp(MyApp());
}

//assign string for models
const String ssd='SSD MobileNet';
const String yolo='Tiny YOLOv2';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        textTheme: TextTheme().copyWith(
          title:TextStyle(color: Colors.white,fontWeight: FontWeight.bold)
        ),
      ),
      
      home:SplashScreenView(
        imageSrc: 'assets/playstore.png',
        home: TfliteHome(),
        duration: 300,
        text: "ISearch",
        textType: TextType.ScaleAnimatedText,
        textStyle: TextStyle(color: Colors.deepOrange,fontWeight: FontWeight.bold,fontSize: 34),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class TfliteHome extends StatefulWidget {

  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  String _model=yolo;
  File _image;

  List _recognitions;

  double _imagewidth;
  double _imageheight;
  bool _busy=false;


  selectFromImagePicker() async{
    var image=await ImagePicker.pickImage(source: ImageSource.camera);
    if(image==null)return;
    setState(() {
      _busy=true;
    });
    predictImage(image);
  }

  predictImage(File image) async{
    if(image==null)return;
    //choose the model
    if(_model==yolo){
      await yolov2Tiny(image);
    }
    else{
      await ssdMobileNet(image);
    }
    FileImage(image).resolve(ImageConfiguration()).addListener((ImageStreamListener((ImageInfo info,bool _){
     setState(() {
       _imagewidth=info.image.width.toDouble();
       _imageheight=info.image.height.toDouble();
     });
    })));

    setState(() {
      _image=image;
      _busy=false;
    });
  }

  yolov2Tiny(File image) async{
    var recognitions=await Tflite.detectObjectOnImage(
      path: image.path,
      model: 'YOLO',
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1,
    );
    setState(() {
      _recognitions=recognitions;
    });
  }

  ssdMobileNet(File image) async{
    var recognitions=await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );
    setState(() {
      _recognitions=recognitions;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _busy=true;
    loadModel().then((val){
      setState(() {
        _busy=false;
      });
    });
  }

  //choose model
  loadModel() async{
    Tflite.close();
    try{
      String res;
      if(_model==yolo){
        res=await Tflite.loadModel(model: 'assets/tflite/yolov2_tiny.tflite',labels: 'assets/tflite/yolov2_tiny.txt');
      }
      else{
        res=await Tflite.loadModel(model: 'assets/tflite/ssd_mobilenet.tflite',labels: 'assets/tflite/ssd_mobilenet.txt');
      }
      print(res);
    }on PlatformException{
      print('Failed to load model');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size=MediaQuery.of(context).size;
    List<Widget> stackChildren=[];

    List<Widget> renderBoxes(Size screen){
      if(_recognitions==null)return [];
      if(_imagewidth==null || _imageheight==null) return [];

      double factorX=screen.width;
      double factorY=_imageheight/_imageheight*screen.width;


      return _recognitions.map((re){
        return Positioned(
        left: re["rect"]["x"]*factorX,
          top: re["rect"]["y"]*factorY,
          width: re["rect"]["w"]*factorX,
          height: re["rect"]["h"]*factorY,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 3,
              ),
            ),
            child: Text('${re['detectedClass']} ${((re['confidenceInClass'])*100).toStringAsFixed(0)}%',
            style: TextStyle(
              background: Paint()..color.red,
              fontSize: 15,
              color: Colors.white,
            ),
            ),
          ),
        );
      }).toList();
    };
    
    if(_image!=null)
    stackChildren.add(
      Positioned(
        bottom: MediaQuery.of(context).size.height*0.08,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Detected Objects:',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.deepOrange,fontSize: 16),),
            ),
            SizedBox(height: 6,),
            Row(children: [
             ... _recognitions.map((re){
                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 4),
                     child: RaisedButton(
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       child: Text('${re['detectedClass']}'.toUpperCase(),style: Theme.of(context).textTheme.title),
                       onPressed: (){
                         Navigator.of(context).push(MaterialPageRoute(builder: (context)=>MapScreen(re['detectedClass'])));
                       },
                       color: Colors.indigo,
                     ),
                   );
              }).toList(),
            ],),
          ],
        ),
      ),
    );

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      height: size.height*0.75,
      child: _image==null?Image.asset('assets/bg.png') : Image.file(_image),
    ));

    stackChildren.addAll(
      renderBoxes(size),
    );

    if(_busy){
      stackChildren.add(Center(
          child:CircularProgressIndicator(),
        ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ISearch'),

      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        tooltip: 'Pick image from gallery',
        onPressed: selectFromImagePicker,
      ),
      body: Stack(
        children: stackChildren,

      ),
    );
  }
}

