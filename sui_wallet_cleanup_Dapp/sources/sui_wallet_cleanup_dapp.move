module sui_wallet_cleanup_dapp::nft_report {
    use sui::table;

    // Store report data for each NFT
    public struct ReportData has key, store {
        id: UID,
        reports: table::Table<address, bool>,
        report_count: u64,
    }

    // Global registry to map object IDs to their report data
    public struct ReportRegistry has key {
        id: UID,
        report_data: table::Table<address, ReportData>,
    }

    public fun init_registry(ctx: &mut TxContext) {
        let registry = ReportRegistry {
            id: object::new(ctx),
            report_data: table::new(ctx),
        };
        transfer::transfer(registry, tx_context::sender(ctx));
    }
    
    /// Report an NFT by its object ID
    public fun report_nft(registry: &mut ReportRegistry, object_id: address, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        // Check if the object_id already has a ReportData entry
        let has_entry = table::contains(&registry.report_data, object_id);
        if (!has_entry) {
            // Create a new ReportData entry
            let mut reports = table::new(ctx);
            table::add(&mut reports, sender, true);
            let data = ReportData {
                id: object::new(ctx),
                reports,
                report_count: 1,
            };
            table::add(&mut registry.report_data, object_id, data);
        } else {
            let data = table::borrow_mut(&mut registry.report_data, object_id);
            let already_reported = table::contains(&data.reports, sender);
            assert!(!already_reported, 0); // i did this to  Prevent duplicate reports
            table::add(&mut data.reports, sender, true);
            data.report_count = data.report_count + 1;
        }
    }

    /// Get the number of reports for a given object ID
    public fun get_report_count(registry: &ReportRegistry, object_id: address): u64 {
        if (!table::contains(&registry.report_data, object_id)) {
            return 0
        };
        let data = table::borrow(&registry.report_data, object_id);
        data.report_count
    }

    /// Check if a user has already reported a given object
    public fun has_reported(registry: &ReportRegistry, object_id: address, user: address): bool {
        if (!table::contains(&registry.report_data, object_id)) {
            return false
        };
        let data = table::borrow(&registry.report_data, object_id);
        table::contains(&data.reports, user)
    }
}