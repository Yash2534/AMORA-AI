async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

async function columnExists(queryInterface, tableName, columnName) {
  if (!(await tableExists(queryInterface, tableName))) return false;
  const columns = await queryInterface.describeTable(tableName);
  return Object.keys(columns).some((column) => column.toLowerCase() === columnName.toLowerCase());
}

async function indexNames(queryInterface, tableName) {
  if (!(await tableExists(queryInterface, tableName))) return new Set();
  return new Set((await queryInterface.showIndex(tableName)).map((index) => index.name));
}

async function addIndex(queryInterface, tableName, fields, options) {
  if ((await indexNames(queryInterface, tableName)).has(options.name)) return;
  await queryInterface.addIndex(tableName, fields, options);
}

const timestamps = (Sequelize) => ({
  createdAt: { type: Sequelize.DATE, allowNull: false },
  updatedAt: { type: Sequelize.DATE, allowNull: false },
});

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'SubscriptionPlans'))) {
      await queryInterface.createTable('SubscriptionPlans', {
        id: { type: Sequelize.STRING(64), primaryKey: true },
        name: { type: Sequelize.STRING(120), allowNull: false },
        displayName: { type: Sequelize.STRING(160), allowNull: false },
        description: { type: Sequelize.STRING(500), allowNull: true },
        priceMinor: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        currency: { type: Sequelize.STRING(3), allowNull: false, defaultValue: 'INR' },
        billingPeriod: { type: Sequelize.ENUM('day', 'week', 'month', 'year'), allowNull: false, defaultValue: 'month' },
        billingInterval: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
        features: { type: Sequelize.JSON, allowNull: false },
        entitlements: { type: Sequelize.JSON, allowNull: false },
        trialDays: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        offerText: { type: Sequelize.STRING(255), allowNull: true },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sortOrder: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'SubscriptionPlans', ['active', 'sortOrder', 'id'], { name: 'subscription_plans_catalog' });

    if (!(await tableExists(queryInterface, 'Subscriptions'))) {
      await queryInterface.createTable('Subscriptions', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        planId: { type: Sequelize.STRING(64), allowNull: false, references: { model: 'SubscriptionPlans', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        status: { type: Sequelize.ENUM('active', 'expired', 'cancelled', 'past_due', 'trialing'), allowNull: false },
        provider: { type: Sequelize.STRING(32), allowNull: false, defaultValue: 'razorpay' },
        providerCustomerId: { type: Sequelize.STRING(120), allowNull: true },
        providerSubscriptionId: { type: Sequelize.STRING(120), allowNull: true },
        startedAt: { type: Sequelize.DATE, allowNull: false },
        currentPeriodStart: { type: Sequelize.DATE, allowNull: false },
        currentPeriodEnd: { type: Sequelize.DATE, allowNull: false },
        autoRenew: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        cancelAtPeriodEnd: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        cancelledAt: { type: Sequelize.DATE, allowNull: true },
        endedAt: { type: Sequelize.DATE, allowNull: true },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'Subscriptions', ['userId'], { unique: true, name: 'subscriptions_user_unique' });
    await addIndex(queryInterface, 'Subscriptions', ['status', 'currentPeriodEnd', 'userId'], { name: 'subscriptions_entitlement_lookup' });
    await addIndex(queryInterface, 'Subscriptions', ['provider', 'providerSubscriptionId'], { unique: true, name: 'subscriptions_provider_reference_unique' });

    if (!(await tableExists(queryInterface, 'Payments'))) {
      await queryInterface.createTable('Payments', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        planId: { type: Sequelize.STRING(64), allowNull: true, references: { model: 'SubscriptionPlans', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        productType: { type: Sequelize.ENUM('subscription', 'wallet_top_up', 'boost'), allowNull: false },
        productReferenceId: { type: Sequelize.STRING(64), allowNull: false },
        provider: { type: Sequelize.STRING(32), allowNull: false, defaultValue: 'razorpay' },
        providerOrderId: { type: Sequelize.STRING(120), allowNull: true },
        providerPaymentId: { type: Sequelize.STRING(120), allowNull: true },
        amountMinor: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        currency: { type: Sequelize.STRING(3), allowNull: false },
        status: { type: Sequelize.ENUM('created', 'authorized', 'paid', 'failed', 'cancelled', 'refunded', 'chargeback'), allowNull: false, defaultValue: 'created' },
        idempotencyKey: { type: Sequelize.STRING(100), allowNull: false },
        failureCode: { type: Sequelize.STRING(100), allowNull: true },
        failureMessage: { type: Sequelize.STRING(500), allowNull: true },
        verifiedAt: { type: Sequelize.DATE, allowNull: true },
        metadata: { type: Sequelize.JSON, allowNull: true },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'Payments', ['userId', 'idempotencyKey'], { unique: true, name: 'payments_user_idempotency_unique' });
    await addIndex(queryInterface, 'Payments', ['provider', 'providerOrderId'], { unique: true, name: 'payments_provider_order_unique' });
    await addIndex(queryInterface, 'Payments', ['provider', 'providerPaymentId'], { unique: true, name: 'payments_provider_payment_unique' });
    await addIndex(queryInterface, 'Payments', ['userId', 'createdAt', 'id'], { name: 'payments_user_history' });

    if (!(await tableExists(queryInterface, 'PaymentEvents'))) {
      await queryInterface.createTable('PaymentEvents', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        paymentId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Payments', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        provider: { type: Sequelize.STRING(32), allowNull: false },
        providerEventId: { type: Sequelize.STRING(160), allowNull: false },
        eventType: { type: Sequelize.STRING(120), allowNull: false },
        payloadHash: { type: Sequelize.STRING(64), allowNull: false },
        payload: { type: Sequelize.JSON, allowNull: false },
        status: { type: Sequelize.ENUM('received', 'processed', 'ignored', 'failed'), allowNull: false, defaultValue: 'received' },
        processedAt: { type: Sequelize.DATE, allowNull: true },
        errorMessage: { type: Sequelize.STRING(500), allowNull: true },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'PaymentEvents', ['provider', 'providerEventId'], { unique: true, name: 'payment_events_provider_event_unique' });
    await addIndex(queryInterface, 'PaymentEvents', ['paymentId', 'createdAt'], { name: 'payment_events_payment_history' });

    if (!(await tableExists(queryInterface, 'Wallets'))) {
      await queryInterface.createTable('Wallets', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        status: { type: Sequelize.ENUM('active', 'frozen', 'closed'), allowNull: false, defaultValue: 'active' },
        creditUnit: { type: Sequelize.STRING(32), allowNull: false, defaultValue: 'AMORAA_CREDITS' },
        balance: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, defaultValue: 0 },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'Wallets', ['userId'], { unique: true, name: 'wallets_user_unique' });

    if (!(await tableExists(queryInterface, 'WalletTransactions'))) {
      await queryInterface.createTable('WalletTransactions', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        walletId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'Wallets', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        type: { type: Sequelize.ENUM('top_up', 'gift_spend', 'boost_spend', 'redemption', 'refund', 'adjustment'), allowNull: false },
        direction: { type: Sequelize.ENUM('credit', 'debit'), allowNull: false },
        amount: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false },
        referenceType: { type: Sequelize.STRING(50), allowNull: false },
        referenceId: { type: Sequelize.STRING(100), allowNull: false },
        idempotencyKey: { type: Sequelize.STRING(100), allowNull: false },
        balanceBefore: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false },
        balanceAfter: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false },
        status: { type: Sequelize.ENUM('posted', 'reversed'), allowNull: false, defaultValue: 'posted' },
        description: { type: Sequelize.STRING(255), allowNull: true },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'WalletTransactions', ['walletId', 'idempotencyKey'], { unique: true, name: 'wallet_transactions_idempotency_unique' });
    await addIndex(queryInterface, 'WalletTransactions', ['userId', 'createdAt', 'id'], { name: 'wallet_transactions_user_history' });
    await addIndex(queryInterface, 'WalletTransactions', ['userId', 'type', 'createdAt'], { name: 'wallet_transactions_type_filter' });

    if (!(await tableExists(queryInterface, 'WalletProducts'))) {
      await queryInterface.createTable('WalletProducts', {
        id: { type: Sequelize.STRING(64), primaryKey: true },
        type: { type: Sequelize.ENUM('top_up', 'redemption'), allowNull: false },
        name: { type: Sequelize.STRING(120), allowNull: false },
        description: { type: Sequelize.STRING(255), allowNull: true },
        credits: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        priceMinor: { type: Sequelize.INTEGER.UNSIGNED, allowNull: true },
        currency: { type: Sequelize.STRING(3), allowNull: true },
        redemptionKind: { type: Sequelize.ENUM('boost'), allowNull: true },
        grantQuantity: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        durationMinutes: { type: Sequelize.INTEGER.UNSIGNED, allowNull: true },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sortOrder: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'WalletProducts', ['type', 'active', 'sortOrder'], { name: 'wallet_products_catalog' });

    if (!(await tableExists(queryInterface, 'BoostProducts'))) {
      await queryInterface.createTable('BoostProducts', {
        id: { type: Sequelize.STRING(64), primaryKey: true },
        name: { type: Sequelize.STRING(120), allowNull: false },
        description: { type: Sequelize.STRING(255), allowNull: true },
        quantity: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
        durationMinutes: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        priceMinor: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        walletCost: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        currency: { type: Sequelize.STRING(3), allowNull: false, defaultValue: 'INR' },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sortOrder: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'BoostProducts', ['active', 'sortOrder', 'id'], { name: 'boost_products_catalog' });

    if (!(await tableExists(queryInterface, 'BoostEntitlements'))) {
      await queryInterface.createTable('BoostEntitlements', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        productId: { type: Sequelize.STRING(64), allowNull: true, references: { model: 'BoostProducts', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        paymentId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Payments', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        walletTransactionId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'WalletTransactions', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        source: { type: Sequelize.ENUM('subscription', 'payment', 'wallet', 'redemption', 'admin'), allowNull: false },
        quantity: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        remainingQuantity: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        durationMinutes: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        status: { type: Sequelize.ENUM('active', 'consumed', 'expired', 'revoked'), allowNull: false, defaultValue: 'active' },
        expiresAt: { type: Sequelize.DATE, allowNull: true },
        idempotencyKey: { type: Sequelize.STRING(100), allowNull: false },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'BoostEntitlements', ['userId', 'idempotencyKey'], { unique: true, name: 'boost_entitlements_user_idempotency_unique' });
    await addIndex(queryInterface, 'BoostEntitlements', ['userId', 'status', 'expiresAt', 'id'], { name: 'boost_entitlements_inventory' });

    if (!(await tableExists(queryInterface, 'Gifts'))) {
      await queryInterface.createTable('Gifts', {
        id: { type: Sequelize.STRING(64), primaryKey: true },
        name: { type: Sequelize.STRING(120), allowNull: false },
        type: { type: Sequelize.ENUM('rose', 'gift'), allowNull: false },
        description: { type: Sequelize.STRING(255), allowNull: true },
        priceCredits: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        creditUnit: { type: Sequelize.STRING(32), allowNull: false, defaultValue: 'AMORAA_CREDITS' },
        assetUrl: { type: Sequelize.STRING(500), allowNull: true },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sortOrder: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'Gifts', ['active', 'sortOrder', 'id'], { name: 'gifts_catalog' });

    if (!(await tableExists(queryInterface, 'GiftTransactions'))) {
      await queryInterface.createTable('GiftTransactions', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        senderId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        recipientId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        giftId: { type: Sequelize.STRING(64), allowNull: false, references: { model: 'Gifts', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        walletTransactionId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'WalletTransactions', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        conversationId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Conversations', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        priceAtPurchase: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        creditUnit: { type: Sequelize.STRING(32), allowNull: false },
        idempotencyKey: { type: Sequelize.STRING(100), allowNull: false },
        status: { type: Sequelize.ENUM('sent', 'refunded', 'reversed'), allowNull: false, defaultValue: 'sent' },
        note: { type: Sequelize.STRING(280), allowNull: true },
        ...timestamps(Sequelize),
      });
    }
    await addIndex(queryInterface, 'GiftTransactions', ['senderId', 'idempotencyKey'], { unique: true, name: 'gift_transactions_sender_idempotency_unique' });
    await addIndex(queryInterface, 'GiftTransactions', ['recipientId', 'createdAt', 'id'], { name: 'gift_transactions_recipient_history' });

    if (!(await columnExists(queryInterface, 'Boosts', 'boostEntitlementId'))) {
      await queryInterface.addColumn('Boosts', 'boostEntitlementId', {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: true,
        references: { model: 'BoostEntitlements', key: 'id' },
        onDelete: 'RESTRICT',
        onUpdate: 'CASCADE',
      });
    }
    if (!(await columnExists(queryInterface, 'Boosts', 'idempotencyKey'))) {
      await queryInterface.addColumn('Boosts', 'idempotencyKey', { type: Sequelize.STRING(100), allowNull: true });
    }
    await addIndex(queryInterface, 'Boosts', ['userId', 'idempotencyKey'], { unique: true, name: 'boosts_user_idempotency_unique' });
  },

  async down() {
    // Financial, entitlement, and purchase records are intentionally retained.
    // A destructive rollback would violate auditability and existing-user safety.
  },
};
