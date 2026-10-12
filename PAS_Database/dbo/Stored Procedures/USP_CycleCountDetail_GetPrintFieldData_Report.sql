/*************************************************************
 ** File:   [USP_CycleCountDetail_GetPrintFieldData_Report]
 ** Author: SAHDEV SALIYA
 ** Description: Returns Cycle Count line data for the Cycle Count print (SSRS) as one row per line + field,
 **              limited to the fields selected in Cycle Count Settings for the count method (Online / Manual)
 **              of the cycle count and ordered by the configured SequenceNo.
 **              Fields flow left to right, 6 per print row (GridRow / GridCol):
 **              row group = LineNum, GridRow; column group = GridCol; column header = HeaderLabel; cell = CellHtml.
 ** Purpose:
 ** Date:   10/09/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR     Date            Author		    Change Description
    1    10/09/2026   SAHDEV SALIYA       [PN-18227] Created
 ** -----------------------------------------------------------
	exec [USP_CycleCountDetail_GetPrintFieldData_Report] 36,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CycleCountDetail_GetPrintFieldData_Report]
@CycleCountId [bigint] NULL,
@MasterCompanyId [int] NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 BEGIN TRY
		DECLARE @CountMethodId INT, @CycleCountSettingId BIGINT, @ColumnsPerRow INT = 6,
				@IsQtyCounted INT, @IsQtyVariance INT, @IsUnitCostAdj INT;

		SELECT @CountMethodId = ISNULL(NULLIF(CC.[CountMethodId], 0), 1),
			   @IsQtyCounted = ISNULL(CC.[IsQtyCounted], 0),
			   @IsQtyVariance = ISNULL(CC.[IsQtyVariance], 0),
			   @IsUnitCostAdj = ISNULL(CC.[IsUnitCoctAdj], 0)
		  FROM [dbo].[CycleCount] CC WITH(NOLOCK)
		 WHERE CC.[CycleCountId] = @CycleCountId AND CC.[MasterCompanyId] = @MasterCompanyId;

		SELECT TOP 1 @CycleCountSettingId = CS.[CycleCountSettingId]
		  FROM [dbo].[CycleCountSettingMaster] CS WITH(NOLOCK)
		 WHERE CS.[MasterCompanyId] = @MasterCompanyId;

		-- All printable fields with their print label and default sequence (= the print layout before it was configurable)
		DECLARE @AllFields TABLE ([FieldKey] VARCHAR(50), [FieldLabel] VARCHAR(50), [DefaultSequenceNo] INT);
		INSERT INTO @AllFields ([FieldKey], [FieldLabel], [DefaultSequenceNo]) VALUES
			('PartNumber',         'PN',             1),
			('PartDescription',    'PN Description', 2),
			('Manufacturer',       'Manufacturer',   3),
			('StockLineNumber',    'Stk Num',        4),
			('SerialNumber',       'Serial Num',     5),
			('Condition',          'Cond',           6),
			('UnitOfMeasure',      'UOM',            7),
			('Site',               'Site',           8),
			('Warehouse',          'Warehouse',      9),
			('Location',           'Location',       10),
			('Shelf',              'Shelf',          11),
			('Bin',                'Bin',            12),
			('QtyOnHand',          'Qty OH',         13),
			('QtyCounted',         'Qty Counted',    14),
			('DifferenceQuantity', 'Qty Variance',   15),
			('UnitCost',           'Unit Cost Adj',  16),
			('ControlNumber',      'Cntl Num',       NULL),
			('IdNumber',           'Cntl ID',        NULL);

		DECLARE @SelectedFields TABLE ([FieldKey] VARCHAR(50), [FieldLabel] VARCHAR(50), [SortNo] INT);

		IF EXISTS (SELECT 1 FROM [dbo].[CycleCountSettingPrintField] PF WITH(NOLOCK)
					WHERE PF.[CycleCountSettingId] = @CycleCountSettingId AND PF.[CountMethodId] = @CountMethodId AND PF.[IsDeleted] = 0)
		BEGIN
			INSERT INTO @SelectedFields ([FieldKey], [FieldLabel], [SortNo])
			SELECT AF.[FieldKey], AF.[FieldLabel], PF.[SequenceNo]
			  FROM [dbo].[CycleCountSettingPrintField] PF WITH(NOLOCK)
			  INNER JOIN @AllFields AF ON AF.[FieldKey] = PF.[FieldKey]
			 WHERE PF.[CycleCountSettingId] = @CycleCountSettingId
			   AND PF.[CountMethodId] = @CountMethodId
			   AND PF.[IsSelected] = 1 AND PF.[IsDeleted] = 0;
		END
		ELSE
		BEGIN
			-- Not configured yet: keep the previous layout, quantity columns driven by the cycle count flags
			INSERT INTO @SelectedFields ([FieldKey], [FieldLabel], [SortNo])
			SELECT [FieldKey], [FieldLabel], [DefaultSequenceNo]
			  FROM @AllFields
			 WHERE [DefaultSequenceNo] IS NOT NULL
			   AND ([FieldKey] <> 'QtyCounted' OR @IsQtyCounted > 0)
			   AND ([FieldKey] <> 'DifferenceQuantity' OR (@IsQtyCounted > 0 AND @IsQtyVariance > 0))
			   AND ([FieldKey] <> 'UnitCost' OR (@IsQtyCounted > 0 AND @IsUnitCostAdj > 0));
		END

		-- Close any gaps so fields fill the grid left to right
		DECLARE @PrintFields TABLE ([FieldKey] VARCHAR(50), [FieldLabel] VARCHAR(50), [SequenceNo] INT, [GridRow] INT, [GridCol] INT);
		INSERT INTO @PrintFields ([FieldKey], [FieldLabel], [SequenceNo], [GridRow], [GridCol])
		SELECT [FieldKey], [FieldLabel], [SequenceNo], ([SequenceNo] - 1) / @ColumnsPerRow, ([SequenceNo] - 1) % @ColumnsPerRow
		  FROM (SELECT [FieldKey], [FieldLabel], ROW_NUMBER() OVER (ORDER BY [SortNo], [FieldKey]) AS [SequenceNo] FROM @SelectedFields) SF;

		;WITH Lines AS (
			SELECT ROW_NUMBER() OVER (ORDER BY CC.[CycleCountDetailId]) AS [LineNum]
				  ,CC.[CycleCountDetailId]
				  ,CASE WHEN LEN(UPPER(CC.[PartNumber])) > 13 then LEFT(UPPER(CC.[PartNumber]), 13) + '...' else UPPER(CC.[PartNumber]) end AS [PartNumber]
				  ,CASE WHEN LEN(UPPER(CC.[PartDescription])) > 23 then LEFT(UPPER(CC.[PartDescription]), 23) + '...' else UPPER(CC.[PartDescription]) end AS [PartDescription]
				  ,CASE WHEN LEN(UPPER(CC.[ManufacturerName])) > 19 then LEFT(UPPER(CC.[ManufacturerName]), 19) + '...' else UPPER(CC.[ManufacturerName]) end AS [ManufacturerName]
				  ,CC.[UnitOfMeasureName]
				  ,CC.[ConditionName]
				  ,CASE WHEN LEN(UPPER(CC.[SerialNumber])) > 15 then LEFT(UPPER(CC.[SerialNumber]), 15) + '...' else UPPER(CC.[SerialNumber]) end AS [SerialNumber]
				  ,CC.[StockLineNumber]
				  ,CC.[ControlNumber]
				  ,CC.[IdNumber]
				  ,CASE WHEN LEN(UPPER(CC.[Site])) > 18 then LEFT(UPPER(CC.[Site]), 18) + '...' else UPPER(CC.[Site]) end AS [Site]
				  ,CASE WHEN LEN(UPPER(CC.[Warehouse])) > 9 then LEFT(UPPER(CC.[Warehouse]), 9) + '...' else UPPER(CC.[Warehouse]) end AS [Warehouse]
				  ,CASE WHEN LEN(UPPER(CC.[Location])) > 8 then LEFT(UPPER(CC.[Location]), 8) + '...' else UPPER(CC.[Location]) end AS [Location]
				  ,CASE WHEN LEN(UPPER(CC.[Shelf])) > 8 then LEFT(UPPER(CC.[Shelf]), 8) + '...' else UPPER(CC.[Shelf]) end AS [Shelf]
				  ,CASE WHEN LEN(UPPER(CC.[Bin])) > 7 then LEFT(UPPER(CC.[Bin]), 7) + '...' else UPPER(CC.[Bin]) end AS [Bin]
				  ,ISNULL(SL.[QuantityOnHand], 0) AS [QuantityOnHand]
				  ,ISNULL(CC.[CountedQuantity], 0) AS [CountedQuantity]
				  ,ISNULL(CC.[DifferenceQuantity], 0) AS [DifferenceQuantity]
				  ,ISNULL(CC.[DifferenceAmount], 0) AS [DifferenceAmount]
			 FROM [dbo].[CycleCountDetail] CC WITH(NOLOCK)
			 INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = CC.[StockLineId]
			 WHERE CC.[MasterCompanyId] = @MasterCompanyId
			   AND CC.[CycleCountId] = @CycleCountId AND ISNULL(SL.IsNonStock,0) = 0
		),
		FieldValues AS (
			SELECT L.[LineNum], L.[CycleCountDetailId], V.[FieldKey],
				   -- HTML encode, the report cell uses HTML markup
				   REPLACE(REPLACE(REPLACE(ISNULL(V.[FieldValue], ''), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS [FieldValue]
			  FROM Lines L
			  CROSS APPLY (VALUES
					('PartNumber',         CAST(L.[PartNumber] AS NVARCHAR(100))),
					('PartDescription',    CAST(L.[PartDescription] AS NVARCHAR(100))),
					('Manufacturer',       CAST(L.[ManufacturerName] AS NVARCHAR(100))),
					('UnitOfMeasure',      CAST(L.[UnitOfMeasureName] AS NVARCHAR(100))),
					('Condition',          CAST(L.[ConditionName] AS NVARCHAR(100))),
					('SerialNumber',       CAST(L.[SerialNumber] AS NVARCHAR(100))),
					('StockLineNumber',    CAST(L.[StockLineNumber] AS NVARCHAR(100))),
					('ControlNumber',      CAST(L.[ControlNumber] AS NVARCHAR(100))),
					('IdNumber',           CAST(L.[IdNumber] AS NVARCHAR(100))),
					('Site',               CAST(L.[Site] AS NVARCHAR(100))),
					('Warehouse',          CAST(L.[Warehouse] AS NVARCHAR(100))),
					('Location',           CAST(L.[Location] AS NVARCHAR(100))),
					('Shelf',              CAST(L.[Shelf] AS NVARCHAR(100))),
					('Bin',                CAST(L.[Bin] AS NVARCHAR(100))),
					('QtyOnHand',          CASE WHEN L.[QuantityOnHand] < 0 THEN '(' + FORMAT(ABS(L.[QuantityOnHand]), '#,0') + ')' ELSE FORMAT(L.[QuantityOnHand], '#,0') END),
					('QtyCounted',         CASE WHEN L.[CountedQuantity] = 0 THEN '_______'
												WHEN L.[CountedQuantity] < 0 THEN '(' + FORMAT(ABS(L.[CountedQuantity]), 'N2') + ')' ELSE FORMAT(L.[CountedQuantity], 'N2') END),
					('DifferenceQuantity', CASE WHEN L.[DifferenceQuantity] < 0 THEN '(' + FORMAT(ABS(L.[DifferenceQuantity]), 'N2') + ')' ELSE FORMAT(L.[DifferenceQuantity], 'N2') END),
					('UnitCost',           CASE WHEN L.[DifferenceAmount] < 0 THEN '(' + FORMAT(ABS(L.[DifferenceAmount]), 'N2') + ')' ELSE FORMAT(L.[DifferenceAmount], 'N2') END)
			  ) V([FieldKey], [FieldValue])
		)
		SELECT FV.[LineNum]
			  ,PF.[GridRow]
			  ,PF.[GridCol]
			  ,HDR.[FieldLabel] AS [HeaderLabel]
			  -- First print row sits under the column header, later rows carry their own label
			  ,CASE WHEN PF.[GridRow] = 0 THEN FV.[FieldValue]
					ELSE '<b> ' + PF.[FieldLabel] + ':  </b>' + FV.[FieldValue] END AS [CellHtml]
		  FROM FieldValues FV
		  INNER JOIN @PrintFields PF ON PF.[FieldKey] = FV.[FieldKey]
		  INNER JOIN @PrintFields HDR ON HDR.[GridRow] = 0 AND HDR.[GridCol] = PF.[GridCol]
		 ORDER BY FV.[LineNum], PF.[SequenceNo];
 END TRY
 BEGIN CATCH
  IF @@trancount > 0
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountDetail_GetPrintFieldData_Report'
			, @ProcedureParameters VARCHAR(3000) = '@CycleCountId = ''' + CAST(ISNULL(@CycleCountId, '') AS VARCHAR(100))
												 + ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
 END CATCH
END
