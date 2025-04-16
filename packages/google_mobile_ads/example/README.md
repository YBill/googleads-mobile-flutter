# google_mobile_ads_example

Demonstrates how to use the google_mobile_ads plugin.

## Getting Started

For help getting started with Flutter, view our online
[documentation](http://flutter.io/).

### Native Ads Use

0、In the original load() method of SDK, factoryId and templateStyle must be passed one

```flutter
_nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: AdRequest(),
      factoryId: 'adFactoryExample',
      nativeTemplateStyle: NativeTemplateStyle(),
    )..load();
```

1、Preload ad use preLoad(), factoryId and templateStyle not required

```flutter
_nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: AdRequest(),
    )..preLoad();
```

2、If you use preLoad() to load ads without passing factoryId and templateStyle, you must call the factoryId() or templateStyle() methods before displaying ads.

```flutter
await _nativeAd.setFactoryId("");
// or
await _nativeAd.setTemplateStyle(NativeTemplateStyle());
```

before use

```flutter
AdWidget(ad: _nativeAd)
```