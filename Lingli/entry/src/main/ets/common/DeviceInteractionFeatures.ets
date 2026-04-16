/**
 * 碰一碰 / 抓一抓（隔空传送）分享 + 智感握姿（握持手感知）
 */

import { harmonyShare, systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileUri, fileIo } from '@kit.CoreFileKit';
import { motion } from '@kit.MultimodalAwarenessKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import util from '@ohos.util';

const DOMAIN = 0x5001;
const TAG = 'DeviceInteraction';
const SHARE_FILE_NAME = 'neighbor_share.txt';
const SHARE_TEXT = '邻里社区便民服务\nhttps://harmonycare.cn\n（由邻里 App 分享）';

export class DeviceInteractionFeatures {
  private static shareListenerRegistered: boolean = false;
  private static graspSubscribed: boolean = false;
  private static lastGraspError: string = '';

  static registerShareListeners(ctx: common.UIAbilityContext | undefined): void {
    if (DeviceInteractionFeatures.shareListenerRegistered) {
      return;
    }
    if (!ctx) {
      hilog.warn(DOMAIN, TAG, 'registerShareListeners skipped: context unavailable');
      return;
    }
    try {
      DeviceInteractionFeatures.registerKnockShare(ctx);
      DeviceInteractionFeatures.registerGesturesShare(ctx);
      DeviceInteractionFeatures.shareListenerRegistered = true;
      hilog.info(DOMAIN, TAG, 'share listeners registered');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'registerShareListeners failed: %{public}s', JSON.stringify(err));
    }
  }

  static unregisterShareListeners(): void {
    if (!DeviceInteractionFeatures.shareListenerRegistered) {
      return;
    }
    try {
      harmonyShare.off('knockShare');
      harmonyShare.off('gesturesShare');
      DeviceInteractionFeatures.shareListenerRegistered = false;
      hilog.info(DOMAIN, TAG, 'share listeners unregistered');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'unregisterShareListeners failed: %{public}s', JSON.stringify(err));
    }
  }

  private static registerKnockShare(ctx: common.UIAbilityContext): void {
    harmonyShare.on('knockShare', (target: harmonyShare.SharableTarget) => {
      DeviceInteractionFeatures.handleShare(ctx, target);
    });
  }

  private static registerGesturesShare(ctx: common.UIAbilityContext): void {
    harmonyShare.on('gesturesShare', (target: harmonyShare.SharableTarget) => {
      DeviceInteractionFeatures.handleShare(ctx, target);
    });
  }

  private static handleShare(ctx: common.UIAbilityContext, target: harmonyShare.SharableTarget): void {
    try {
      const cachePath = `${ctx.cacheDir}/${SHARE_FILE_NAME}`;
      const file = fileIo.openSync(
        cachePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
      );
      const encoder = new util.TextEncoder();
      const content: Uint8Array = encoder.encode(SHARE_TEXT);
      fileIo.writeSync(file.fd, content);
      fileIo.closeSync(file);

      const uri = fileUri.getUriFromPath(cachePath);
      if (!uri || uri.length === 0) {
        hilog.error(DOMAIN, TAG, 'share uri empty');
        return;
      }

      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.txt', utd.UniformDataType.TEXT);
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: uri,
        title: '邻里',
        description: '社区便民服务'
      });
      shareData.addRecord({
        utd: utdTypeId,
        uri: uri
      });
      target.share(shareData);
      hilog.info(DOMAIN, TAG, 'share dispatched');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'handleShare failed: %{public}s', JSON.stringify(err));
    }
  }

  static isPhoneDevice(): boolean {
    const type = deviceInfo.deviceType;
    return type === 'phone' || type === 'default' || type === 'unknown';
  }

  static getLastGraspError(): string {
    return DeviceInteractionFeatures.lastGraspError;
  }

  static async enableGraspFeature(ctx: common.UIAbilityContext | undefined): Promise<boolean> {
    if (!ctx) {
      DeviceInteractionFeatures.lastGraspError = 'context_unavailable';
      hilog.warn(DOMAIN, TAG, 'enableGraspFeature failed: context unavailable');
      return false;
    }
    const granted = await DeviceInteractionFeatures.requestRuntimePermissions(ctx, [
      'ohos.permission.DETECT_GESTURE' as Permissions
    ]);
    if (!granted) {
      DeviceInteractionFeatures.lastGraspError = 'permission_denied';
      return false;
    }
    if (DeviceInteractionFeatures.graspSubscribed) {
      DeviceInteractionFeatures.lastGraspError = '';
      return true;
    }
    try {
      motion.on('holdingHandChanged', (status: motion.HoldingHandStatus) => {
        const handStatus = status as number;
        if (handStatus === 1) {
          AppStorage.setOrCreate('isAIButtonRight', false);
        } else if (handStatus === 2) {
          AppStorage.setOrCreate('isAIButtonRight', true);
        }
      });
      DeviceInteractionFeatures.graspSubscribed = true;
      DeviceInteractionFeatures.lastGraspError = '';
      hilog.info(DOMAIN, TAG, 'holdingHandChanged subscribed');
      return true;
    } catch (err) {
      const be = err as BusinessError;
      if (be.code === 801) {
        DeviceInteractionFeatures.lastGraspError = 'unsupported';
        hilog.warn(DOMAIN, TAG, 'device may not support holdingHandChanged');
      } else {
        DeviceInteractionFeatures.lastGraspError = 'subscribe_failed';
        hilog.error(DOMAIN, TAG, 'enableGraspFeature failed: %{public}s', JSON.stringify(err));
      }
      return false;
    }
  }

  static disableGraspFeature(): void {
    DeviceInteractionFeatures.lastGraspError = '';
    if (!DeviceInteractionFeatures.graspSubscribed) {
      AppStorage.setOrCreate('isAIButtonRight', true);
      return;
    }
    try {
      motion.off('holdingHandChanged');
      DeviceInteractionFeatures.graspSubscribed = false;
      AppStorage.setOrCreate('isAIButtonRight', true);
      hilog.info(DOMAIN, TAG, 'holdingHandChanged unsubscribed');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'disableGraspFeature failed: %{public}s', JSON.stringify(err));
    }
  }

  static async requestRuntimePermissions(ctx: common.UIAbilityContext | undefined, perms: Permissions[]): Promise<boolean> {
    if (!ctx) {
      hilog.warn(DOMAIN, TAG, 'requestRuntimePermissions failed: context unavailable');
      return false;
    }
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(ctx, perms);
      if (!result.authResults || result.authResults.length === 0) {
        return true;
      }
      let i = 0;
      while (i < result.authResults.length) {
        if (result.authResults[i] !== 0) {
          return false;
        }
        i++;
      }
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'requestRuntimePermissions failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }
}
