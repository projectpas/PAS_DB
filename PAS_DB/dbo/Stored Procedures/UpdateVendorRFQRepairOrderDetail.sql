CREATE PROCEDURE [dbo].[UpdateVendorRFQRepairOrderDetail]
@VendorRFQRepairOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		---------Vendor RFQ  Repair Order --------------------------------------------------------------
				
		DECLARE @MSID as bigint
		DECLARE @Level1 as varchar(200)
		DECLARE @Level2 as varchar(200)
		DECLARE @Level3 as varchar(200)
		DECLARE @Level4 as varchar(200)

		IF OBJECT_ID(N'tempdb..#VendorRFQRepairOrderPartMSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #VendorRFQRepairOrderPartMSDAT 
		END
		CREATE TABLE #VendorRFQRepairOrderPartMSDAT
		(
		 MSID bigint,
		 Level1 varchar(200) NULL,
		 Level2 varchar(200) NULL,
		 Level3 varchar(200) NULL,
		 Level4 varchar(200) NULL 
		)

		IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #MSDATA 
		END
		CREATE TABLE #MSDATA
		(
			ID int IDENTITY, 
			MSID bigint 
		)
		INSERT INTO #MSDATA (MSID) SELECT PO.ManagementStructureId FROM [dbo].[VendorRFQRepairOrder] PO WITH (NOLOCK) Where PO.VendorRFQRepairOrderId = @VendorRFQRepairOrderId

		INSERT INTO #MSDATA (MSID)
		  SELECT DISTINCT ROP.ManagementStructureId FROM dbo.VendorRFQRepairOrder ROP WITH (NOLOCK) Where ROP.VendorRFQRepairOrderId = @VendorRFQRepairOrderId
				  AND ROP.ManagementStructureId 
				  NOT IN (SELECT MSID FROM #MSDATA)

		DECLARE @LoopID as int 
		SELECT  @LoopID = MAX(ID) FROM #MSDATA
		WHILE(@LoopID > 0)
		BEGIN
		SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

		EXEC dbo.GetMSNameandCode @MSID,
		 @Level1 = @Level1 OUTPUT,
		 @Level2 = @Level2 OUTPUT,
		 @Level3 = @Level3 OUTPUT,
		 @Level4 = @Level4 OUTPUT

		INSERT INTO #VendorRFQRepairOrderPartMSDAT
					(MSID, Level1,Level2,Level3,Level4)
			  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
		SET @LoopID = @LoopID - 1;
		END 
				
		UPDATE RO SET
		RO.[Priority] = PR.Description,
		RO.VendorName = V.VendorName,
		RO.VendorCode = V.VendorCode,
		RO.VendorContact = ISNULL(C.FirstName,'') + ' ' + ISNULL(C.LastName,''),
		RO.VendorContactPhone = ISNULL(C.WorkPhone,'') + '-' + ISNULL(C.WorkPhoneExtn,''),
		RO.Terms = CT.Name,
		RO.CreditLimit = ISNULL(V.CreditLimit,0.00),
		RO.Status = RS.[Description],
		RO.Requisitioner = ISNULL(e.FirstName,'') + ' ' + ISNULL(e.LastName,''),
		RO.Level1 = RMS.Level1,
		RO.Level2 = RMS.Level2,
		RO.Level3 = RMS.Level3,
		RO.Level4 = RMS.Level4
		
		FROM dbo.VendorRFQRepairOrder RO WITH (NOLOCK)
		LEFT JOIN #VendorRFQRepairOrderPartMSDAT RMS ON RMS.MSID = RO.ManagementStructureId
		LEFT JOIN dbo.VendorRFQStatus RS WITH (NOLOCK) on RS.VendorRFQStatusId = RO.StatusId
		LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = RO.VendorId
		LEFT JOIN dbo.VendorContact VC WITH (NOLOCK) ON VC.VendorContactId = RO.VendorContactId
		LEFT JOIN dbo.Contact C WITH (NOLOCK) ON  VC.ContactId =  C.ContactId
		LEFT JOIN dbo.CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId = RO.CreditTermsId
		LEFT JOIN dbo.Employee E WITH (NOLOCK) on RO.RequisitionerId =  E.EmployeeId	
		LEFT JOIN dbo.Priority PR WITH (NOLOCK)  ON  PR.PriorityId = RO.PriorityId
		WHERE RO.VendorRFQRepairOrderId = @VendorRFQRepairOrderId;					   							

		UPDATE dbo.VendorRFQRepairOrderPart SET
		   PartNumber = IM.partnumber,
		   PartDescription = IM.PartDescription,
		   AltEquiPartNumber = AIM.PartNumber,
		   AltEquiPartDescription = AIM.PartDescription,
		   StockType = (CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 
							'PMA&DER' 
							WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA' 
							WHEN IM.IsPma = 0 AND IM.IsDER = 1  THEN 'DER' 
							ELSE 'OEM'
							END),
		   Manufacturer = MF.[NAME],
		   [Priority] = PR.[Description],
		   Condition = CO.[Description],
		   --FunctionalCurrency = CR.Code,
		   --ReportCurrency= RC.Code,
		   --StockLineNumber = SL.StockLineNumber,
		   --ControlId = SL.IdNumber,
		   --ControlNumber = SL.ControlNumber,
		   --PurchaseOrderNumber= Po.PurchaseOrderNumber, 
		   WorkOrderNo =  WO.WorkOrderNum ,
		   SubWorkOrderNo =SWO.SubWorkOrderNo, 
		   SalesOrderNo = SO.SalesOrderNumber,
		   ItemTypeId = IM.ItemTypeId,
		   ItemType = IT.[Description],   
		   --GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,'')),
		   UnitOfMeasure = UOM.ShortName,
		   Level1 = RMS.Level1,
		   Level2 = RMS.Level2,
		   Level3 = RMS.Level3,
		   Level4 = RMS.Level4,	
		   RevisedPartNumber = RIM.partnumber,
		   WorkPerformed = WP.CapabilityTypeDesc

		FROM  dbo.VendorRFQRepairOrderPart ROP WITH (NOLOCK)
			  INNER JOIN #VendorRFQRepairOrderPartMSDAT RMS ON RMS.MSID = ROP.ManagementStructureId
			  --INNER JOIN RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId=ROP.RepairOrderId	
			  INNER JOIN ItemMaster IM WITH (NOLOCK) ON ROP.ItemMasterId=IM.ItemMasterId	
			  INNER JOIN Condition CO WITH (NOLOCK) ON CO.ConditionId = ROP.ConditionId
			  INNER JOIN Priority PR WITH (NOLOCK) ON PR.PriorityId = ROP.PriorityId
			  --INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId = ROP.FunctionalCurrencyId
			  --INNER JOIN Currency RC WITH (NOLOCK) ON RC.CurrencyId = ROP.ReportCurrencyId
			  INNER JOIN Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = ROP.ManufacturerId
			  --INNER JOIN GLAccount    GLA WITH (NOLOCK) ON GLA.GLAccountId = ROP.GlAccountId
			  INNER JOIN UnitOfMeasure  UOM WITH (NOLOCK)  ON UOM.UnitOfMeasureId = ROP.UOMId
			  LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = ROP.WorkOrderId
			  LEFT JOIN ItemType ITP WITH (NOLOCK) ON ITP.ItemTypeId= ROP.ItemTypeId
			  LEFT JOIN SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = ROP.SubWorkOrderId	  
			  LEFT JOIN SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = ROP.SalesOrderId
			  LEFT JOIN ItemMaster AIM WITH (NOLOCK) ON AIM.ItemMasterId = ROP.AltEquiPartNumberId			  
			  LEFT JOIN ItemMaster ST WITH (NOLOCK) ON ST.ItemMasterId=ROP.ItemMasterId	
			  LEFT JOIN ItemType IT WITH (NOLOCK) ON IM.ItemTypeId = IT.ItemTypeId				 
			  LEFT JOIN ItemMaster RIM WITH (NOLOCK) ON ROP.RevisedPartId=RIM.ItemMasterId	
			  --LEFT JOIN WorkPerformed WP WITH (NOLOCK) ON ROP.WorkPerformedId=WP.WorkPerformedId	
			  LEFT JOIN CapabilityType WP WITH (NOLOCK) ON ROP.WorkPerformedId=WP.CapabilityTypeId

		WHERE ROP.VendorRFQRepairOrderId = @VendorRFQRepairOrderId; 
		
		SELECT VendorRFQRepairOrderNumber AS value FROM dbo.VendorRFQRepairOrder PO WITH (NOLOCK) WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateVendorRFQRepairOrderDetail' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQRepairOrderId, '') + ''
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