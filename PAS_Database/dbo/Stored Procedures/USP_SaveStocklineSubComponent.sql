/*************************************************************
 ** File:   [USP_SaveStocklineSubComponent]
 ** Description: Saves the sub-components of a parent stockline (Add Sub Component popup).
                 @tbl_SubComponents is the COMPLETE list the user sees in the popup.

                 Relation is 1 to 1 (a stockline belongs to one parent) and one level deep.

                 New row (not linked yet), Qty = N, source stockline S:
                   - N = S.QuantityOnHand (whole stockline, e.g. 5 of 5) -> S itself is linked:
                       SubComponentParentStocklineId = parent, SubComponentQty = N (quantities not changed)
                   - N < S.QuantityOnHand (e.g. 3 of 10) -> USP_SplitStocklineForSubComponent creates a new
                       stockline with N (OH = Available = N, Reserved = 0) linked to the parent,
                       and S keeps the rest (OH / Qty / Available reduced by N).
                 Linking does NOT reserve qty (same as Lot split) - it only records the parent.
                 Already linked row  : kept as is (Qty can not be changed - remove and add again).
                 Linked row missing  : unlinked (link columns cleared, quantities not changed;
                                       a split stockline stays as its own stockline).
 ** Date:   10/15/2026
 ** Author:  Kishor Makwana

 ** RETURN VALUE: Status (1 = success, 0 = validation failed), Message
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    10/15/2026  Kishor Makwana    [PN-18321] Created

-- DECLARE @tbl StocklineSubComponentType; INSERT INTO @tbl VALUES (2, 3);
-- EXEC [dbo].[USP_SaveStocklineSubComponent] @ParentStocklineId = 1, @tbl_SubComponents = @tbl, @MasterCompanyId = 1, @UpdatedBy = 'admin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveStocklineSubComponent]
	@ParentStocklineId BIGINT,
	@tbl_SubComponents StocklineSubComponentType READONLY,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @ModuleId BIGINT = 0,
				@LinkActionId INT = NULL,
				@UnLinkActionId INT = NULL,
				@SplitActionId INT = NULL,
				@ParentSubComponentOf BIGINT = NULL;

		SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'StockLine';
		SELECT @LinkActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-Link';
		SELECT @UnLinkActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-UnLink';
		SELECT @SplitActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'SubComponent-Split';
		-- history rows are written only when the actions exist (sprint data script)

		DECLARE @Input TABLE ([StockLineId] BIGINT PRIMARY KEY, [Qty] DECIMAL(18, 6));
		INSERT INTO @Input ([StockLineId], [Qty])
		SELECT [StockLineId], SUM(ISNULL([Qty], 0))
		FROM @tbl_SubComponents
		WHERE [StockLineId] IS NOT NULL
		GROUP BY [StockLineId];

		/* ---------- parent validation ---------- */
		IF NOT EXISTS (SELECT 1 FROM [dbo].[Stockline] WITH (NOLOCK)
					   WHERE [StockLineId] = @ParentStocklineId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([isDeleted], 0) = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], 'Parent stockline not found.' AS [Message];
			RETURN;
		END

		SELECT @ParentSubComponentOf = [SubComponentParentStocklineId]
		FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @ParentStocklineId;

		IF (@ParentSubComponentOf IS NOT NULL AND EXISTS (SELECT 1 FROM @Input))
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], 'This stockline is already a sub-component of another stockline, so sub-components can not be added to it.' AS [Message];
			RETURN;
		END

		/* ---------- build work list (lock the rows we will change) ---------- */
		-- Mode: 'KEEP' = already linked, 'LINK' = link whole stockline, 'SPLIT' = split qty to a new stockline, 'UNLINK'
		DECLARE @Work TABLE (
			[StockLineId] BIGINT PRIMARY KEY,
			[StockLineNumber] VARCHAR(100) NULL,
			[Qty] DECIMAL(18, 6) NOT NULL,
			[Mode] VARCHAR(10) NULL,
			[ErrorMessage] VARCHAR(500) NULL);

		INSERT INTO @Work ([StockLineId], [StockLineNumber], [Qty], [Mode], [ErrorMessage])
		SELECT i.[StockLineId],
			   s.[StockLineNumber],
			   i.[Qty],
			   CASE
				   WHEN s.[SubComponentParentStocklineId] = @ParentStocklineId THEN 'KEEP'
				   WHEN i.[Qty] >= ISNULL(s.[QuantityOnHand], 0) THEN 'LINK'
				   ELSE 'SPLIT'
			   END,
			   CASE
				   WHEN s.[StockLineId] IS NULL THEN 'Stockline not found.'
				   WHEN s.[SubComponentParentStocklineId] = @ParentStocklineId AND i.[Qty] <> ISNULL(s.[SubComponentQty], 0)
						THEN 'Qty of a saved sub component can not be changed. Remove it and add again.'
				   WHEN s.[SubComponentParentStocklineId] = @ParentStocklineId THEN NULL
				   WHEN s.[StockLineId] = @ParentStocklineId THEN 'A stockline can not be its own sub-component.'
				   WHEN ISNULL(s.[isDeleted], 0) = 1 OR ISNULL(s.[IsNonStock], 0) = 1 OR ISNULL(s.[IsParent], 1) = 0 THEN 'Stockline can not be used as a sub-component.'
				   WHEN s.[SubComponentParentStocklineId] IS NOT NULL THEN 'Stockline is already a sub-component of another stockline.'
				   WHEN EXISTS (SELECT 1 FROM [dbo].[Stockline] c WITH (NOLOCK) WHERE c.[SubComponentParentStocklineId] = s.[StockLineId]) THEN 'Stockline has its own sub-components.'
				   WHEN i.[Qty] <= 0 THEN 'Qty must be greater than 0.'
				   WHEN ISNULL(s.[isSerialized], 0) = 1 AND i.[Qty] <> 1 THEN 'Qty must be 1 for a serialized stockline.'
				   WHEN i.[Qty] > ISNULL(s.[QuantityAvailable], 0) THEN 'Qty can not be more than Qty Available.'
				   ELSE NULL
			   END
		FROM @Input i
		LEFT JOIN [dbo].[Stockline] s WITH (UPDLOCK, ROWLOCK) ON s.[StockLineId] = i.[StockLineId] AND s.[MasterCompanyId] = @MasterCompanyId;

		-- rows currently linked but removed in the popup
		INSERT INTO @Work ([StockLineId], [StockLineNumber], [Qty], [Mode], [ErrorMessage])
		SELECT s.[StockLineId], s.[StockLineNumber], ISNULL(s.[SubComponentQty], 0), 'UNLINK', NULL
		FROM [dbo].[Stockline] s WITH (UPDLOCK, ROWLOCK)
		WHERE s.[SubComponentParentStocklineId] = @ParentStocklineId
		  AND NOT EXISTS (SELECT 1 FROM @Input i WHERE i.[StockLineId] = s.[StockLineId]);

		IF EXISTS (SELECT 1 FROM @Work WHERE [ErrorMessage] IS NOT NULL)
		BEGIN
			DECLARE @ErrorText VARCHAR(MAX);
			SELECT @ErrorText = STUFF((SELECT '; ' + ISNULL(w.[StockLineNumber], CONVERT(VARCHAR(20), w.[StockLineId])) + ' - ' + w.[ErrorMessage]
									   FROM @Work w WHERE w.[ErrorMessage] IS NOT NULL
									   FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 2, '');
			ROLLBACK TRANSACTION;
			SELECT 0 AS [Status], @ErrorText AS [Message];
			RETURN;
		END

		/* ---------- UNLINK : clear the link ---------- */
		UPDATE s
		SET s.[SubComponentParentStocklineId] = NULL,
			s.[SubComponentQty] = NULL,
			s.[IsSubComponent] = 0,
			s.[UpdatedBy] = @UpdatedBy,
			s.[UpdatedDate] = GETUTCDATE()
		FROM [dbo].[Stockline] s
		INNER JOIN @Work w ON w.[StockLineId] = s.[StockLineId]
		WHERE w.[Mode] = 'UNLINK';

		/* ---------- LINK : whole stockline becomes the sub-component ---------- */
		UPDATE s
		SET s.[SubComponentParentStocklineId] = @ParentStocklineId,
			s.[SubComponentQty] = w.[Qty],
			s.[IsSubComponent] = 1,
			s.[UpdatedBy] = @UpdatedBy,
			s.[UpdatedDate] = GETUTCDATE()
		FROM [dbo].[Stockline] s
		INNER JOIN @Work w ON w.[StockLineId] = s.[StockLineId]
		WHERE w.[Mode] = 'LINK';

		/* ---------- SPLIT + history ---------- */
		DECLARE @CurStocklineId BIGINT, @CurQty DECIMAL(18, 6), @CurMode VARCHAR(10), @CurActionId INT, @NewStocklineId BIGINT, @NewCount INT = 0;

		DECLARE WorkCursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT [StockLineId], [Qty], [Mode] FROM @Work WHERE [Mode] IN ('UNLINK', 'LINK', 'SPLIT');

		OPEN WorkCursor;
		FETCH NEXT FROM WorkCursor INTO @CurStocklineId, @CurQty, @CurMode;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (@CurMode = 'SPLIT')
			BEGIN
				SET @NewStocklineId = NULL;
				EXEC [dbo].[USP_SplitStocklineForSubComponent] @StocklineId = @CurStocklineId, @Qty = @CurQty,
					 @ParentStocklineId = @ParentStocklineId, @UpdatedBy = @UpdatedBy, @NewStocklineId = @NewStocklineId OUTPUT;
				SET @NewCount = @NewCount + 1;

				-- source: qty moved out ; new stockline: linked to parent
				IF (@SplitActionId IS NOT NULL)
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @CurStocklineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
						 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @SplitActionId, @Qty = @CurQty, @UpdatedBy = @UpdatedBy;
				IF (@LinkActionId IS NOT NULL)
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @NewStocklineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
						 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @LinkActionId, @Qty = @CurQty, @UpdatedBy = @UpdatedBy;
			END
			ELSE
			BEGIN
				SET @CurActionId = CASE WHEN @CurMode = 'LINK' THEN @LinkActionId ELSE @UnLinkActionId END;
				IF (@CurActionId IS NOT NULL)
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @CurStocklineId, @ModuleId = @ModuleId, @ReferenceId = @ParentStocklineId,
						 @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @CurActionId, @Qty = @CurQty, @UpdatedBy = @UpdatedBy;
			END

			FETCH NEXT FROM WorkCursor INTO @CurStocklineId, @CurQty, @CurMode;
		END
		CLOSE WorkCursor;
		DEALLOCATE WorkCursor;

		COMMIT TRANSACTION;
		SELECT 1 AS [Status],
			   'Sub components saved successfully.' + CASE WHEN @NewCount > 0 THEN ' ' + CONVERT(VARCHAR(10), @NewCount) + ' new stockline(s) created.' ELSE '' END AS [Message];

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SaveStocklineSubComponent'
			, @ProcedureParameters VARCHAR(3000) = '@ParentStocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@ParentStocklineId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''', @UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END