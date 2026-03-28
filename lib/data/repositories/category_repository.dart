import '../database/app_database.dart';
import '../database/daos/category_dao.dart';

class CategoryRepository {
  const CategoryRepository(this._categoryDao);

  final CategoryDao _categoryDao;

  Stream<List<CategoriesTableData>> watchMainCategories() {
    return _categoryDao.watchMainCategories();
  }

  Stream<List<CategoriesTableData>> watchDollarCategories() {
    return _categoryDao.watchDollarCategories();
  }

  Future<List<CategoriesTableData>> getMainCategories() {
    return _categoryDao.getMainCategories();
  }

  Future<CategoriesTableData?> getCategoryById(int id) {
    return _categoryDao.getCategoryById(id);
  }

  Future<int> createCategory(CategoriesTableCompanion entry) {
    return _categoryDao.insertCategory(entry);
  }
}
