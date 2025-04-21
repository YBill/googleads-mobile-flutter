import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

void _log(String msg) {
  print('NativeAdExample: -----> $msg');
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Native Ad'),
          ),
          body: Center(
            child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NativeAdPage()),
                  );
                },
                child: Text('Native Ad Page')),
          ),
        );
      }),
    );
  }
}

class NativeAdPage extends StatefulWidget {
  @override
  State<NativeAdPage> createState() => _NativeAdPageState();
}

class _NativeAdPageState extends State<NativeAdPage> {
  NativeAd? _nativeAd;
  bool _isAdBindByFactory = false;
  bool _isAdBindByTemplateStyle = false;

  Future<void> _preloadAd(String adUnitId, Function(NativeAd?) onAdLoaded) async {
    _log('preloadAd, adUnitId: $adUnitId');
    await NativeAd(
      adUnitId: adUnitId,
      request: AdRequest(),
      // factoryId: 'adFactoryExample',
      // nativeTemplateStyle: ,
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          _log('loaded, adUnitId: ${ad.adUnitId}');
          onAdLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _log('$NativeAd failedToLoad: $error,\nadUnitId: ${ad.adUnitId}');
          ad.dispose();
          onAdLoaded(null);
        },
        onAdOpened: (Ad ad) => _log('onAdOpened, adUnitId: ${ad.adUnitId}'),
        onAdClosed: (Ad ad) => _log('onAdClosed, adUnitId: ${ad.adUnitId}'),
      ),
    ).preLoad();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Native Ad Page'),
      ),
      body: Stack(children: <Widget>[
        Center(
          child: Column(children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () {
                      final adUnitId = Platform.isAndroid ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-3940256099942544/3986624511';
                      if (_nativeAd == null) {
                        _preloadAd(adUnitId, (nativeAd) => _nativeAd = nativeAd);
                      }
                    },
                    child: Text('Preload Ad A')),
                TextButton(
                    onPressed: () {
                      final adUnitId = 'ca-app-pub-3940256099942544/9782828514';
                      if (_nativeAd == null) {
                        _preloadAd(adUnitId, (nativeAd) => _nativeAd = nativeAd);
                      }
                    },
                    child: Text('Preload Ad B')),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () async {
                      await _nativeAd?.bindViewByFactoryId("adFactoryExample");
                      _isAdBindByFactory = true;
                      setState(() {});
                    },
                    child: Text('Show Ad By Factory')),
                TextButton(
                    onPressed: () async {
                      await _nativeAd?.bindViewByTemplateStyle(NativeTemplateStyle(
                        templateType: TemplateType.small,
                        mainBackgroundColor: Colors.blue,
                        callToActionTextStyle: NativeTemplateTextStyle(
                          size: 16.0,
                        ),
                        primaryTextStyle: NativeTemplateTextStyle(
                          textColor: Colors.black38,
                          backgroundColor: Colors.white70,
                        ),
                      ));
                      _isAdBindByTemplateStyle = true;
                      setState(() {});
                    },
                    child: Text('Show Ad By TemplateStyle')),
              ],
            ),
          ]),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isAdBindByFactory) _buildNativeAdWidget(_nativeAd, true),
              if (_isAdBindByTemplateStyle) _buildNativeAdWidget(_nativeAd, true),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildNativeAdWidget(NativeAd? nativeAd, bool isAdALoaded) {
    const double _nativeAdHeight = 320.0;
    return Stack(children: [
      SizedBox(height: _nativeAdHeight, width: MediaQuery.of(context).size.width),
      if (nativeAd != null && isAdALoaded) SizedBox(height: _nativeAdHeight, width: MediaQuery.of(context).size.width, child: AdWidget(ad: nativeAd))
    ]);
  }
}
