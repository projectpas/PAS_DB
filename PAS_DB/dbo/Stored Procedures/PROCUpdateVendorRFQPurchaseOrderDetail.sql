

--- EXEC PROCUpdateVendorRFQPurchaseOrderDetail  1
CREATE PROCEDURE [dbo].[PROCUpdateVendorRFQPurchaseOrderDetail]
@VendorRFQPurchaseOrderId  bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN			
				
		DECLARE @MSID as bigint
		DECLARE @Level1 as varchar(200)
		DECLARE @Level2 as varchar(200)
		DECLARE @Level3 as varchar(200)
		DECLARE @Level4 as varchar(200)

		IF OBJECT_ID(N'tempdb..#VendorRFQPurchaseOrderMSDATA') IS NOT NULL
		BEGIN
		DROP TABLE #VendorRFQPurchaseOrderMSDATA
		END
		CREATE TABLE #VendorRFQPurchaseOrderMSDATA
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
		INSERT INTO #MSDATA (MSID) SELECT PO.ManagementStructureId FROM dbo.VendorRFQPurchaseOrder PO Where PO.VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId

		INSERT INTO #MSDATA (MSID)
		  SELECT DISTINCT POP.ManagementStructureId
			 FROM dbo.VendorRFQPurchaseOrderPart POP Where POP.VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId
				  AND POP.ManagementStructureId 
				  NOT IN (SELECT MSID FROM #MSDATA)

		DECLARE @LoopID AS int 
		SELECT  @LoopID = MAX(ID) FROM #MSDATA
		WHILE(@LoopID > 0)
		BEGIN
			SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

			EXEC dbo.GetMSNameandCode @MSID,
			@Level1 = @Level1 OUTPUT,
			@Level2 = @Level2 OUTPUT,
			@Level3 = @Level3 OUTPUT,
			@Level4 = @Level4 OUTPUT

			INSERT INTO #VendorRFQPurchaseOrderMSDATA
					(MSID, Level1,Level2,Level3,Level4)
			  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
			SET @LoopID = @LoopID - 1;
		END 
 
		UPDATE PO SET
		PO.[Priority] = PR.[Description],
		PO.VendorName = V.VendorName,
		PO.VendorCode = V.VendorCode,
		PO.VendorContact = ISNULL(C.FirstName,'') + ' ' + ISNULL(C.LastName,''),
		PO.VendorContactPhone = ISNULL(C.WorkPhone,'') + '-' + ISNULL(C.WorkPhoneExtn,''),
		PO.Terms = CT.[Name],
		PO.CreditLimit = ISNULL(V.CreditLimit,0.00),
		PO.Status = PS.[Description],
		PO.Requisitioner = ISNULL(e.FirstName,'') + ' ' + ISNULL(e.LastName,''),
		PO.Level1 = PMS.Level1,
		PO.Level2 = PMS.Level2,
		PO.Level3 = PMS.Level3,
		PO.Level4 = PMS.Level4
		
		FROM dbo.VendorRFQPurchaseOrder PO WITH (NOLOCK)
		LEFT JOIN #VendorRFQPurchaseOrderMSDATA PMS ON PMS.MSID = PO.ManagementStructureId
		LEFT JOIN dbo.VendorRFQStatus PS WITH (NOLOCK) on PS.VendorRFQStatusId = PO.StatusId
		LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = PO.VendorId
		LEFT JOIN dbo.VendorContact VC WITH (NOLOCK) ON VC.VendorContactId = PO.VendorContactId
		LEFT JOIN dbo.Contact C WITH (NOLOCK) ON  VC.ContactId =  C.ContactId
		LEFT JOIN dbo.CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId = PO.CreditTermsId
		LEFT JOIN dbo.Employee E WITH (NOLOCK) on PO.RequestedBy =  E.EmployeeId		
		LEFT JOIN Priority PR WITH (NOLOCK)  ON  PR.PriorityId = PO.PriorityId
		WHERE PO.VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId;
				   

		UPDATE dbo.VendorRFQPurchaseOrderPart
		SET PartNumber = IM.partnumber,
			PartDescription = IM.PartDescription,		  
			StockType = (CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER' 
							WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA' 
							WHEN IM.IsPma = 0 AND IM.IsDER = 1  THEN 'DER' 
							ELSE 'OEM'
							END),
		    Manufacturer = MF.[NAME],
		    [Priority] = PR.[Description],
		    Condition = CO.[Description],		  
		    WorkOrderNo =  WO.WorkOrderNum ,
		    SubWorkOrderNo =SWO.SubWorkOrderNo,		   
		    SalesOrderNo = SO.SalesOrderNumber,		   
		    Level1 = PMS.Level1,
		    Level2 = PMS.Level2,
		    Level3 = PMS.Level3,
		    Level4 = PMS.Level4,
			UnitOfMeasure = UOM.ShortName
			
		FROM  dbo.VendorRFQPurchaseOrderPart POP WITH (NOLOCK)
			  INNER JOIN #VendorRFQPurchaseOrderMSDATA PMS ON PMS.MSID = POP.ManagementStructureId
			  INNER JOIN dbo.ItemMaster IM  WITH (NOLOCK) ON POP.ItemMasterId=IM.ItemMasterId		 
			  INNER JOIN dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = POP.ConditionId
			  INNER JOIN dbo.Priority PR WITH (NOLOCK) ON PR.PriorityId = POP.PriorityId			  
			  INNER JOIN dbo.Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = POP.ManufacturerId			  
			  LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = POP.WorkOrderId
			  LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = POP.SubWorkOrderId			  
			  LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = POP.SalesOrderId
			  LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = POP.UOMId
		WHERE POP.VendorRFQPurchaseOrderId  = @VendorRFQPurchaseOrderId; 

		SELECT VendorRFQPurchaseOrderNumber AS value FROM dbo.VendorRFQPurchaseOrder PO WITH (NOLOCK) WHERE VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId	

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'PROCUpdateVendorRFQPurchaseOrderDetail' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPurchaseOrderId, '') + ''
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