import '../models/brand_model.dart';
import '../models/store_model.dart';
import '../models/comment_model.dart';
import '../models/price_model.dart';
import '../models/product_suggestion_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/actual_model.dart';
import '../models/actual_item_model.dart';
import '../models/category_model.dart';
import '../models/banner_model.dart';
import '../models/campaign_basket_model.dart';
import 'firestore_service.dart';

class BrandDomainService {
  BrandDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<BrandModel>> getAllBrands() => _firestoreService.getAllBrands();
  Stream<List<BrandModel>> getActiveBrands() => _firestoreService.getActiveBrands();
}

class StoreDomainService {
  StoreDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<StoreModel>> getAllStoresStream() =>
      _firestoreService.getAllStoresStream();
  Stream<List<StoreModel>> getActiveStores() =>
      _firestoreService.getActiveStores();
  Stream<List<StoreModel>> getNearbyActiveStoresStream() =>
      _firestoreService.getNearbyActiveStoresStream();
  Stream<List<StoreModel>> getOnlineActiveStoresStream() =>
      _firestoreService.getOnlineActiveStoresStream();
}


class AdminModerationDomainService {
  AdminModerationDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<Map<String, dynamic>>> getReports() =>
      _firestoreService.getReports();

  Future<void> updateReportStatus(
    String reportId,
    String status, {
    String? resolvedBy,
    String? resolutionNote,
  }) =>
      _firestoreService.updateReportStatus(
        reportId,
        status,
        resolvedBy: resolvedBy,
        resolutionNote: resolutionNote,
      );

  Future<void> deleteReport(String reportId) =>
      _firestoreService.deleteReport(reportId);

  Future<CommentModel?> getCommentById(String commentId) =>
      _firestoreService.getCommentById(commentId);

  Future<PriceModel?> getPriceById(String priceId) =>
      _firestoreService.getPriceById(priceId);

  Future<ProductModel?> getProduct(String productId) =>
      _firestoreService.getProduct(productId);

  Future<UserModel?> getUserById(String userId) =>
      _firestoreService.getUserById(userId);

  Stream<bool> getMaintenanceMode() => _firestoreService.getMaintenanceMode();

  Future<void> setMaintenanceMode(bool enabled) =>
      _firestoreService.setMaintenanceMode(enabled);
}


class ProductSuggestionDomainService {
  ProductSuggestionDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<ProductSuggestionModel>> getPendingProductSuggestions() =>
      _firestoreService.getPendingProductSuggestions();

  Future<void> approveProductSuggestion(String suggestionId) =>
      _firestoreService.approveProductSuggestion(suggestionId);

  Future<void> rejectProductSuggestion(String suggestionId) =>
      _firestoreService.rejectProductSuggestion(suggestionId);
}


class AdminUserManagementDomainService {
  AdminUserManagementDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<void> updateUserByAdmin(String uid, Map<String, dynamic> data) =>
      _firestoreService.updateUserByAdmin(uid, data);

  Future<void> setUserBanStatusByAdmin({
    required String userId,
    required bool isBanned,
    String? reason,
    String? adminUid,
  }) =>
      _firestoreService.setUserBanStatusByAdmin(
        userId: userId,
        isBanned: isBanned,
        reason: reason,
        adminUid: adminUid,
      );

  Future<void> deleteUserByAdmin(String uid) =>
      _firestoreService.deleteUserByAdmin(uid);
}


class AdminBrandManagementDomainService {
  AdminBrandManagementDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<void> addBrand(BrandModel brand) => _firestoreService.addBrand(brand);

  Future<void> updateBrand(String brandId, Map<String, dynamic> data) =>
      _firestoreService.updateBrand(brandId, data);

  Future<String> addStore(StoreModel store) => _firestoreService.addStore(store);

  Future<void> updateStore(String storeId, Map<String, dynamic> data) =>
      _firestoreService.updateStore(storeId, data);
}


class ActualAdminDomainService {
  ActualAdminDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<ActualModel>> getActualsForAdmin({bool? isActive}) =>
      _firestoreService.getActualsForAdmin(isActive: isActive);

  Stream<ActualModel?> getLatestActiveActualForUser() =>
      _firestoreService.getLatestActiveActualForUser();

  Stream<List<ActualItemModel>> getActualItems(String actualId) =>
      _firestoreService.getActualItems(actualId);

  Future<void> setActualActive(String actualId, bool isActive) =>
      _firestoreService.setActualActive(actualId, isActive);

  Future<void> addActual(ActualModel actual) => _firestoreService.addActual(actual);

  Future<void> updateActual(String actualId, Map<String, dynamic> data) =>
      _firestoreService.updateActual(actualId, data);

  Future<void> addActualItem(String actualId, ActualItemModel item) =>
      _firestoreService.addActualItem(actualId, item);

  Future<void> updateActualItem(
    String actualId,
    String itemId,
    Map<String, dynamic> data,
  ) =>
      _firestoreService.updateActualItem(actualId, itemId, data);

  Future<void> deleteActualItem(String actualId, String itemId) =>
      _firestoreService.deleteActualItem(actualId, itemId);
}


class AdminCategoryManagementDomainService {
  AdminCategoryManagementDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<String> addCategory(
    String title,
    String iconName, {
    String? imageUrl,
    String? imagePath,
    bool isActive = true,
    int? order,
  }) =>
      _firestoreService.addCategory(
        title,
        iconName,
        imageUrl: imageUrl,
        imagePath: imagePath,
        isActive: isActive,
        order: order,
      );

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) =>
      _firestoreService.updateCategory(categoryId, data);

  Future<void> deleteCategory(String categoryId) =>
      _firestoreService.deleteCategory(categoryId);
}


class AdminBannerManagementDomainService {
  AdminBannerManagementDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<String> addBanner(BannerModel banner) =>
      _firestoreService.addBanner(banner);

  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) =>
      _firestoreService.updateBanner(bannerId, data);
}


class AdminCampaignManagementDomainService {
  AdminCampaignManagementDomainService(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<String> addCampaign(CampaignBasketModel campaign) =>
      _firestoreService.addCampaign(campaign);

  Future<void> updateCampaign(String id, Map<String, dynamic> data) =>
      _firestoreService.updateCampaign(id, data);

  Future<void> deleteCampaign(String id) => _firestoreService.deleteCampaign(id);
}
