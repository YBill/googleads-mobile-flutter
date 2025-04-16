##### 这里的代码是基于 Flutter Admob SDK 5.3.1 版本进行修改：

地址：https://github.com/googleads/googleads-mobile-flutter/tree/v5.3.1

修改原因是 `Native` 广告加载时需要绑定广告样式，导致 `Native` 广告预加载后不能复用，下面修改后将广告的加载和广告样式分离，加载时只加载广告，在使用广告时再设置广告样式。

改动思路是之前广告的加载还可以使用，新增了预加载广告方法和绑定广告样式方法；因为 `Native` 广告绑定样式有两种方式（factoryId或nativeTemplateStyle），所以总共新增三个方法实现；

在 `Flutter` 端新增三个方法，在 `Android` 和 `iOS` 端分别实现：

##### 1、Flutter：

（1）ad_containers.dart

```dart
    /// [New] added by Bill
    /// It's not necessary to bind styles
    /// If there is not binding style. setFactoryId or setTemplateStyle must be called before the ad is show
    Future<void> preLoad() async {
      await instanceManager.preLoadNativeAd(this);
    }
    
    /// [New] added by Bill
    /// set factory id.
    Future<void> setFactoryId(String factoryId) async {
      return instanceManager.setNativeAdFactoryId(this, factoryId);
    }
    
    /// [New] added by Bill
    /// set template style
    Future<void> setTemplateStyle(NativeTemplateStyle nativeTemplateStyle) async {
      return instanceManager.setNativeAdTemplateStyle(this, nativeTemplateStyle);
    }
```

（2）ad_instance_manager.dart

```dart
    /// [New] added by Bill
    /// It's not necessary to bind styles
    Future<void> preLoadNativeAd(NativeAd ad) {
      if (adIdFor(ad) != null) {
        return Future<void>.value();
      }
    
      final int adId = _nextAdId++;
      _loadedAds[adId] = ad;
      return channel.invokeMethod<void>(
        'preLoadNativeAd',
        <dynamic, dynamic>{
          'adId': adId,
          'adUnitId': ad.adUnitId,
          'request': ad.request,
          'adManagerRequest': ad.adManagerRequest,
          'factoryId': ad.factoryId,
          'nativeAdOptions': ad.nativeAdOptions,
          'customOptions': ad.customOptions,
          'nativeTemplateStyle': ad.nativeTemplateStyle,
        },
      );
    }
    
    /// [New] added by Bill
    /// set factory id.
    Future<void> setNativeAdFactoryId(NativeAd ad, String factoryId) async {
      return channel.invokeMethod<void>('setNativeAdFactoryId', <dynamic, dynamic>{
        'adId': adIdFor(ad),
        'factoryId': factoryId,
      });
    }
    
    /// [New] added by Bill
    /// set template style
    Future<void> setNativeAdTemplateStyle(NativeAd ad, NativeTemplateStyle nativeTemplateStyle) async {
      return channel.invokeMethod<void>('setNativeAdTemplateStyle', <dynamic, dynamic>{
        'adId': adIdFor(ad),
        'nativeTemplateStyle': nativeTemplateStyle,
      });
    }  
```

##### 2、Android：

（1）GoogleMobileAdsPlugin.java

```java
public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    switch (call.method) {
        case "preLoadNativeAd":
            final NativeAdFactory preLoadNativeAdFactory = nativeAdFactories.get(call.<String>argument("factoryId"));
            final FlutterNativeTemplateStyle preLoadNativeAdTemplateStyle = call.argument("nativeTemplateStyle");
            if (preLoadNativeAdFactory == null && preLoadNativeAdTemplateStyle == null) {
                Log.i(TAG, "preLoad NativeAd, No binding style");
            }

            final FlutterNativeAd preLoadNativeAd =
                    new FlutterNativeAd.Builder(context)
                            .setManager(instanceManager)
                            .setAdUnitId(call.<String>argument("adUnitId"))
                            .setAdFactory(preLoadNativeAdFactory)
                            .setRequest(call.<FlutterAdRequest>argument("request"))
                            .setAdManagerRequest(call.<FlutterAdManagerAdRequest>argument("adManagerRequest"))
                            .setCustomOptions(call.<Map<String, Object>>argument("customOptions"))
                            .setId(call.<Integer>argument("adId"))
                            .setNativeAdOptions(call.<FlutterNativeAdOptions>argument("nativeAdOptions"))
                            .setFlutterAdLoader(new FlutterAdLoader(context))
                            .setNativeTemplateStyle(preLoadNativeAdTemplateStyle)
                            .build();
            instanceManager.trackAd(preLoadNativeAd, call.<Integer>argument("adId"));
            preLoadNativeAd.load();
            result.success(null);
            break;
        case "setNativeAdFactoryId":
            final NativeAdFactory setNativeAdFIFactory = nativeAdFactories.get(call.<String>argument("factoryId"));
            FlutterNativeAd setNativeAdFINativeAd = (FlutterNativeAd) instanceManager.adForId(call.<Integer>argument("adId"));
            setNativeAdFINativeAd.setAdFactory(setNativeAdFIFactory);
            result.success(null);
            break;
        case "setNativeAdTemplateStyle":
            final FlutterNativeTemplateStyle setNativeAdTSTemplateStyle = call.<FlutterNativeTemplateStyle>argument("nativeTemplateStyle");
            FlutterNativeAd setNativeAdTSNativeAd = (FlutterNativeAd) instanceManager.adForId(call.<Integer>argument("adId"));
            setNativeAdTSNativeAd.setNativeTemplateStyle(setNativeAdTSTemplateStyle);
            result.success(null);
            break;
    }
}
```

（2）FlutterNativeAd.java

```java
    private NativeAd nativeAd;
    void onNativeAdLoaded(@NonNull NativeAd nativeAd) {
        if (adFactory == null && nativeTemplateStyle == null) {
            this.nativeAd = nativeAd;
        } else {
            if (nativeTemplateStyle != null) {
                templateView = nativeTemplateStyle.asTemplateView(context);
                templateView.setNativeAd(nativeAd);
            } else {
                nativeAdView = adFactory.createNativeAd(nativeAd, customOptions);
            }
        }
    
        nativeAd.setOnPaidEventListener(new FlutterPaidEventListener(manager, this));
        manager.onAdLoaded(adId, nativeAd.getResponseInfo());
    }

    void setAdFactory(@NonNull NativeAdFactory adFactory) {
        if (nativeAdView != null) {
            return;
        }
        nativeAdView = adFactory.createNativeAd(nativeAd, customOptions);
    }
    
    void setNativeTemplateStyle(@NonNull FlutterNativeTemplateStyle nativeTemplateStyle) {
        if (templateView != null) {
            return;
        }
        templateView = nativeTemplateStyle.asTemplateView(context);
        templateView.setNativeAd(nativeAd);
    }
```

##### 3、iOS:

