// Default categories and constants for Try mode. No mutable state.
export 'models.dart';
import 'models.dart';

/// Default categories for add-transaction (with subcategories and emojis).
/// Used to seed categories on first launch.
const List<TransactionCategory> defaultTransactionCategories = [
  TransactionCategory(
    id: '1',
    name: 'Food & Dining',
    emoji: '🍴',
    subcategories: [
      SubcategoryItem(name: 'Restaurant', emoji: '🍽️'),
      SubcategoryItem(name: 'Groceries', emoji: '🛒'),
      SubcategoryItem(name: 'Cafe', emoji: '☕'),
      SubcategoryItem(name: 'Delivery', emoji: '📦'),
    ],
  ),
  TransactionCategory(
    id: '2',
    name: 'Shopping',
    emoji: '🛍️',
    subcategories: [
      SubcategoryItem(name: 'Clothing', emoji: '👕'),
      SubcategoryItem(name: 'Electronics', emoji: '📱'),
      SubcategoryItem(name: 'Online', emoji: '🛍️'),
    ],
  ),
  TransactionCategory(
    id: '3',
    name: 'Transport',
    emoji: '🚗',
    subcategories: [
      SubcategoryItem(name: 'Fuel', emoji: '⛽'),
      SubcategoryItem(name: 'Rideshare', emoji: '🚗'),
      SubcategoryItem(name: 'Public Transport', emoji: '🚌'),
    ],
  ),
  TransactionCategory(
    id: '4',
    name: 'Bills & Utilities',
    emoji: '💡',
    subcategories: [
      SubcategoryItem(name: 'Electricity', emoji: '⚡'),
      SubcategoryItem(name: 'Water', emoji: '💧'),
      SubcategoryItem(name: 'Internet', emoji: '📶'),
      SubcategoryItem(name: 'Phone', emoji: '📞'),
    ],
  ),
  TransactionCategory(
    id: '5',
    name: 'Income',
    emoji: '💰',
    subcategories: [
      SubcategoryItem(name: 'Salary', emoji: '💰'),
      SubcategoryItem(name: 'Freelance', emoji: '💼'),
      SubcategoryItem(name: 'Gift', emoji: '🎁'),
      SubcategoryItem(name: 'Refund', emoji: '↩️'),
    ],
  ),
  TransactionCategory(
    id: '6',
    name: 'Transfer',
    emoji: '🔄',
    subcategories: [
      SubcategoryItem(name: 'Between accounts', emoji: '🔄'),
      SubcategoryItem(name: 'To savings', emoji: '🐷'),
    ],
  ),
  TransactionCategory(
    id: '7',
    name: 'Tobacco & Alcohol',
    emoji: '🍺',
    subcategories: [
      SubcategoryItem(name: 'Cigarettes', emoji: '🚬'),
      SubcategoryItem(name: 'Beer', emoji: '🍺'),
      SubcategoryItem(name: 'Wine', emoji: '🍷'),
      SubcategoryItem(name: 'Spirits', emoji: '🥃'),
      SubcategoryItem(name: 'Bar / Pub', emoji: '🍸'),
    ],
  ),
];

/// Account type options for add/edit account.
const List<String> accountTypeOptions = [
  'Mobile Finance',
  'Bank',
  'Debit Card',
  'Credit Card',
  'Savings',
  'Cash',
  'Investment',
  'Wallet',
  'Other',
];

/// Common emojis for account picker.
const List<String> accountEmojiOptions = [
  '🏦', '📱', '💳', '👛', '💰', '🪙', '📊', '🔒', '💵', '💴', '💶', '💷',
  '🐷', '🦊', '🐸', '⭐', '🎯',
];
