part of 'app_pages.dart';

abstract class Routes {
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const HOME = _Paths.HOME;
  static const VIEW_ALL = _Paths.VIEW_ALL; // Route untuk View All
  static const FAVORITE = _Paths.FAVORITE; // Route untuk Favorite
  static const START_COOKING = _Paths.START_COOKING; // Route untuk Start Cooking
  static const UPLOAD = _Paths.UPLOAD; // Route untuk Upload Recipe
  static const MEAL_PLAN = _Paths.MEAL_PLAN;
  static const PROFILE = _Paths.PROFILE;
}

abstract class _Paths {
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const HOME = '/home';
  static const VIEW_ALL = '/view-all'; // Path untuk View All
  static const FAVORITE = '/favorite'; // Path untuk Favorite
  static const START_COOKING = '/start-cooking'; // Path untuk Start Cooking
  static const UPLOAD = '/upload'; // Path untuk Upload Recipe
  static const MEAL_PLAN = '/meal-plan';
  static const PROFILE = '/profile';
}
