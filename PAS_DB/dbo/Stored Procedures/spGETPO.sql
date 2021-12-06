--EXEC spGETPO  'open','2019-12-10 00:00:00.0000000','2020-12-10 00:00:00.0000000'
CREATE Procedure [dbo].[spGETPO]
	@status varchar(10),
	@vendorname varchar(20)=null,
	@fromdate datetime2,
	@todate datetime2
AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
		CASE WHEN	
		level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL and level2.Code IS NOT NULL and level1.Code+level1.Name IS NOT NULL THEN level1.Code+level1.Name 
				   WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL and level2.Code+level2.Name IS NOT NULL THEN level2.Code+level2.Name 
				   WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL THEN level3.Code+level3.Name
				   WHEN level4.Code+level4.Name IS NOT NULL THEN level4.Code+level4.Name ELSE '' END AS LEVEL1,
				   CASE WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL and level2.Code+level2.name IS NOT NULL and level1.Code IS NOT NULL THEN level2.Code+level2.Name
				   WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL and level2.Code+level2.Name IS NOT NULL THEN level3.Code+level3.Name 
				   WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.name IS NOT NULL THEN level4.Code+level4.Name ELSE '' END AS LEVEL2,
				   CASE WHEN level4.Code+level4.Name IS NOT NULL and level3.Code IS NOT NULL and level2.Code+level2.Name IS NOT NULL and level1.Code+level1.Name IS NOT NULL THEN level3.Code+level3.Name
				   WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL and level2.Code+level2.Name IS NOT NULL THEN level4.Code+level4.Name ELSE '' END AS LEVEL3,
				   CASE WHEN level4.Code+level4.Name IS NOT NULL and level3.Code+level3.Name IS NOT NULL and level2.Code+level2.Name IS NOT NULL and level1.Code+level1.Name IS NOT NULL THEN level4.Code+level4.Name ELSE '' END AS LEVEL4,
		PO.PurchaseOrderNumber 'PO NUM',
		convert(varchar,PO.OpenDate,101)'PO Date',
		(IM.partnumber) 'PN',
		(IM.PartDescription) 'PN Description',
		POP.itemtype 'Item Type',
		POP.stocktype 'StockType',
		PO.status  'Status',
		DATEDIFF(day,PO.OpenDate,Getdate())  'PO Age',
		(PO.VendorName)    'Vendor Name',
		PO.VendorCode    'Vendor Code',
		POP.unitofmeasure  'UOM',
		PO.Approvedby         'Approver',
		PO.Requisitioner          'Requisitioner ',
		POP.QuantityOrdered 'Qty',
		POP.UnitCost 'Unit Cost',
		POP.functionalcurrency       'Currency',
		pop.ExtendedCost  'ExtendedCost',
		Convert(varchar,POP.NeedByDate,101)'Need By',
			'?'             'Promise Date',
			'?'			 'Next Del Date'
		FROM PurchaseOrder PO WITH (NOLOCK)
		INNER JOIN PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId=POP.PurchaseOrderId
		INNER JOIN ItemMaster IM WITH (NOLOCK) ON POP.ItemMasterId=IM.ItemMasterId
		INNER JOIN Vendor V WITH (NOLOCK) ON PO.VendorId=V.VendorId
		join  ManagementStructure level4 WITH (NOLOCK) on PO.ManagementStructureId = level4.ManagementStructureId
		LEFT join  ManagementStructure level3 WITH (NOLOCK) on level4.ParentId = level3.ManagementStructureId 
		LEFT join  ManagementStructure level2 WITH (NOLOCK) on level3.ParentId = level2.ManagementStructureId 
		LEFT join  ManagementStructure level1 WITH (NOLOCK) on level2.ParentId = level1.ManagementStructureId
		WHERE PO.Status = @status and PO.OpenDate between @Fromdate and @Todate
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'spGETPO' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@status AS VARCHAR(10)), '') + ''',
												@Parameter2 = ' + ISNULL(@vendorname ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END