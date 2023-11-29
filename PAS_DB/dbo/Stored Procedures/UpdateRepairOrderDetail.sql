
CREATE    Procedure [dbo].[UpdateRepairOrderDetail]
@RepairOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		---------  Repair Order --------------------------------------------------------------
		UPDATE ROS SET
		ROS.StatusId = (SELECT ROStatusId FROM dbo.ROStatus WITH (NOLOCK) Where IsActive = 1 and IsDeleted = 0  and Memo = 'Fulfilling' ),
		ROS.ApproverId = ISNULL((select TOP 1 PA.ApprovedById from dbo.RepairOrderApproval PA WITH (NOLOCK) INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE RepairOrderId = @RepairOrderId ORDER BY ApprovedDate DESC),0),
		ROS.ApprovedDate = (select TOP 1 PA.ApprovedDate from dbo.RepairOrderApproval PA WITH (NOLOCK) 
							INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE RepairOrderId = @RepairOrderId ORDER BY ApprovedDate DESC)
		FROM dbo.RepairOrder ROS WITH (NOLOCK)
		WHERE RepairOrderId = @RepairOrderId
		AND 
		ISNULL((select Count(PA.RepairOrderApprovalId) 
				from dbo.RepairOrderApproval PA WITH (NOLOCK) INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK) 
					 ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
					 INNER JOIN dbo.RepairOrderPart POP WITH (NOLOCK) ON POP.RepairOrderPartRecordId = PA.RepairOrderPartId
					 WHERE POP.RepairOrderId = @RepairOrderId),0) = ISNULL((select Count(RepairOrderPartRecordId) from dbo.RepairOrderPart  WHERE  RepairOrderId = @RepairOrderId and isParent = 1),0)
		AND 
		(select Count(PA.RepairOrderApprovalId) from 
			dbo.RepairOrderApproval PA WITH (NOLOCK) INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK)
				ON PA.StatusId = APS.ApprovalStatusId  AND APS.Name =  'Approved'
		  INNER JOIN dbo.RepairOrderPart POP WITH (NOLOCK) ON POP.RepairOrderPartRecordId = PA.RepairOrderPartId
				WHERE POP.RepairOrderId = @RepairOrderId) > 0
		AND
		(SELECT COUNT(POA.AddressId)  FROM  dbo.AllAddress POA WITH (NOLOCK) 
		   INNER JOIN dbo.Module M WITH (NOLOCK) ON POA.ModuleId = POA.ModuleId
		  WHERE POA.ReffranceId = @RepairOrderId
				 AND POA.IsShippingAdd = 1  AND M.ModuleName = 'RepairOrder')  > 0
		AND
		(SELECT COUNT(POA.AddressId)  FROM  dbo.AllAddress POA WITH (NOLOCK) 
		 INNER JOIN dbo.Module M WITH (NOLOCK) ON POA.ModuleId = POA.ModuleId
		  WHERE POA.ReffranceId = @RepairOrderId
				 AND POA.IsShippingAdd = 0 AND M.ModuleName = 'RepairOrder')  > 0

		UPDATE RepairOrderApproval SET ApprovedById = null , ApprovedDate = null , ApprovedByName = null
		Where RepairOrderId = @RepairOrderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WITH (NOLOCK) WHERE Name  =  'Approved') 


		UPDATE RepairOrderApproval SET RejectedBy = null , RejectedDate =  null , RejectedByName = null
		Where RepairOrderId = @RepairOrderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WITH (NOLOCK) WHERE Name  =  'Rejected') 

		UPDATE RepairOrderApproval
		SET ApprovedByName = AE.FirstName + ' ' + AE.LastName,
			RejectedByName = RE.FirstName + ' ' + RE.LastName,
			StatusName = ASS.Description,
			InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM dbo.RepairOrderApproval PA
			 LEFT JOIN dbo.Employee AE on PA.ApprovedById = AE.EmployeeId
			 LEFT JOIN dbo.Employee RE on PA.RejectedBy = RE.EmployeeId
			 LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = PA.InternalSentToId
			 LEFT JOIN dbo.ApprovalStatus ASS on PA.StatusId = ASS.ApprovalStatusId;


		--DECLARE @MSID as bigint
		--DECLARE @Level1 as varchar(200)
		--DECLARE @Level2 as varchar(200)
		--DECLARE @Level3 as varchar(200)
		--DECLARE @Level4 as varchar(200)

		--IF OBJECT_ID(N'tempdb..#RepairOrderPartMSDATA') IS NOT NULL
		--BEGIN
		--DROP TABLE #RepairOrderPartMSDATA 
		--END
		--CREATE TABLE #RepairOrderPartMSDATA
		--(
		-- MSID bigint,
		-- Level1 varchar(200) NULL,
		-- Level2 varchar(200) NULL,
		-- Level3 varchar(200) NULL,
		-- Level4 varchar(200) NULL 
		--)

		--IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
		--BEGIN
		--DROP TABLE #MSDATA 
		--END
		--CREATE TABLE #MSDATA
		--(
		--	ID int IDENTITY, 
		--	MSID bigint 
		--)
		--INSERT INTO #MSDATA (MSID)
		--  SELECT PO.ManagementStructureId FROM dbo.RepairOrder PO WITH (NOLOCK) Where PO.RepairOrderId = @RepairOrderId

		--INSERT INTO #MSDATA (MSID)
		--  SELECT DISTINCT ROP.ManagementStructureId
		--	 FROM dbo.RepairOrderPart ROP WITH (NOLOCK) Where ROP.RepairOrderId = @RepairOrderId
		--		  AND ROP.ManagementStructureId 
		--		  NOT IN (SELECT MSID FROM #MSDATA)

		--DECLARE @LoopID as int 
		--SELECT  @LoopID = MAX(ID) FROM #MSDATA
		--WHILE(@LoopID > 0)
		--BEGIN
		--SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

		--EXEC dbo.GetMSNameandCode @MSID,
		-- @Level1 = @Level1 OUTPUT,
		-- @Level2 = @Level2 OUTPUT,
		-- @Level3 = @Level3 OUTPUT,
		-- @Level4 = @Level4 OUTPUT

		--INSERT INTO #RepairOrderPartMSDATA
		--			(MSID, Level1,Level2,Level3,Level4)
		--	  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
		--SET @LoopID = @LoopID - 1;
		--END 


		--IF OBJECT_ID(N'tempdb..#RepairOrderPartStockline') IS NOT NULL
		--BEGIN
		--DROP TABLE #RepairOrderPartStockline 
		--END
		--CREATE TABLE #RepairOrderPartStockline
		--(
		-- RepairOrderPartRecordId bigint,
		-- QuantityOrdered int,
		-- QuantityReserved int,
		-- StockLineId  bigint null,
		-- TobeReserved  int
		-- )

		--INSERT INTO #RepairOrderPartStockline
		--(RepairOrderPartRecordId,QuantityOrdered,QuantityReserved,StockLineId,TobeReserved)
		--SELECT RepairOrderPartRecordId,QuantityOrdered,ISNULL(QuantityReserved,0),StockLineId,
		--      ISNULL(QuantityOrdered,0) - ISNULL(QuantityReserved,0)
		--      from dbo.RepairOrderPart  WHERE  RepairOrderId = @RepairOrderId and IsParent = 1

		--UPDATE dbo.Stockline 
		--      SET QuantityReserved = ISNULL(ST.QuantityReserved,0) + ISNULL(RST.TobeReserved,0),
		--		  QuantityAvailable = ISNULL(ST.QuantityAvailable,0) - ISNULL(RST.TobeReserved,0)	     
		--	  from dbo.Stockline ST
		--      INNER JOIN #RepairOrderPartStockline RST 	
		--	  on ST.StockLineId = RST.StockLineId AND ISNULL(RST.TobeReserved,0) > 0
		--	  INNER JOIN dbo.RepairOrderPart ROP
		--	  ON ROP.RepairOrderPartRecordId = RST.RepairOrderPartRecordId AND ROP.IsDeleted = 0

		--UPDATE dbo.Stockline 
		--      SET QuantityReserved = ISNULL(ST.QuantityReserved,0) - ISNULL(ROP.QuantityOrdered,0),
		--		  QuantityAvailable = ISNULL(ST.QuantityAvailable,0) + ISNULL(ROP.QuantityOrdered,0)	     
		--	  from dbo.Stockline ST
		--	  INNER JOIN dbo.RepairOrderPart ROP
		--	  ON ROP.RepairOrderPartRecordId = ST.RepairOrderPartRecordId AND ROP.IsDeleted = 1

		UPDATE dbo.RepairOrderPart
			   SET IsDeleted = 1
			   FROM dbo.RepairOrderPart R
					WHERE R.RepairOrderPartRecordId 
						in (SELECT RepairOrderPartRecordId FROM dbo.RepairOrderPart WHERE  RepairOrderId = @RepairOrderId and IsParent = 1 AND IsDeleted = 1)


		--UPDATE RepairOrderPart 
		--     SET QuantityReserved = QuantityOrdered
		--	 FROM  dbo.RepairOrderPart  WHERE  RepairOrderId = @RepairOrderId and IsParent = 1

		DELETE ROA FROM dbo.RepairOrderApproval  ROA
					  INNER JOIN dbo.RepairOrderPart P
								ON ROA.RepairOrderPartId = P.RepairOrderPartRecordId			
						WHERE P.RepairOrderId = @RepairOrderId AND P.IsDeleted = 1

		DELETE FROM dbo.RepairOrderPart		
						WHERE RepairOrderId = @RepairOrderId AND IsDeleted = 1	


		UPDATE RO SET
		RO.[Priority] = PR.Description,
		RO.VendorName = V.VendorName,
		RO.VendorCode = V.VendorCode,
		RO.VendorContact = ISNULL(C.FirstName,'') + ' ' + ISNULL(C.LastName,''),
		RO.VendorContactPhone = ISNULL(C.WorkPhone,'') + '-' + ISNULL(C.WorkPhoneExtn,''),
		RO.VendorContactEmail = ISNULL(C.Email,''),
		RO.Terms = CT.Name,
		RO.CreditLimit = ISNULL(V.CreditLimit,0.00),
		RO.Status = RS.Description,
		RO.Requisitioner = ISNULL(e.FirstName,'') + ' ' + ISNULL(e.LastName,''),
		--RO.Level1 = RMS.Level1,
		--RO.Level2 = RMS.Level2,
		--RO.Level3 = RMS.Level3,
		--RO.Level4 = RMS.Level4,
		RO.ApprovedBy = ISNULL(AP.FirstName,'') + ' ' + ISNULL(AP.LastName,'')
		FROM dbo.RepairOrder RO WITH (NOLOCK)
		--LEFT JOIN #RepairOrderPartMSDATA RMS ON RMS.MSID = RO.ManagementStructureId
		LEFT JOIN ROStatus RS WITH (NOLOCK) on RS.ROStatusId = RO.StatusId
		LEFT JOIN Vendor V WITH (NOLOCK) ON V.VendorId = RO.VendorId
		LEFT JOIN VendorContact VC WITH (NOLOCK) ON VC.VendorContactId = RO.VendorContactId
		LEFT JOIN Contact C WITH (NOLOCK) ON  VC.ContactId =  C.ContactId
		LEFT JOIN CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId = RO.CreditTermsId
		LEFT JOIN Employee E WITH (NOLOCK) on RO.RequisitionerId =  E.EmployeeId
		LEFT JOIN Employee AP WITH (NOLOCK) ON RO.ApproverId = AP.EmployeeId
		LEFT JOIN Priority PR WITH (NOLOCK)  ON  PR.PriorityId = RO.PriorityId
		WHERE RO.RepairOrderId = @RepairOrderId;



		UPDATE POP SET 
		POP.RoPartSplitUserTypeId = POA.UserType,
		RoPartSplitUserType = POA.UserTypeName,
		POP.RoPartSplitUserId = POA.UserId,
		POP.RoPartSplitUser = POA.UserName,
		POP.RoPartSplitSiteId = POA.SiteId,
		POP.RoPartSplitSiteName = POA.SiteName,
		POP.RoPartSplitAddressId = POA.AddressId,
		POP.RoPartSplitAddress1 =  POA.Line1,
		POP.RoPartSplitAddress2 =  POA.Line2,
		POP.RoPartSplitAddress3=  POA.Line3,
		POP.RoPartSplitCity=  POA.City,
		POP.RoPartSplitStateOrProvince=  POA.StateOrProvince,
		POP.RoPartSplitPostalCode=  POA.PostalCode,
		POP.RoPartSplitCountryId =  POA.CountryId,
		POP.RoPartSplitCountry =  POA.Country
		FROM  dbo.RepairOrderPart POP WITH (NOLOCK)
		INNER JOIN dbo.AllAddress  POA WITH (NOLOCK) 
				 ON POA.ReffranceId = POP.RepairOrderId 
				 AND POA.IsShippingAdd = 1
		INNER JOIN dbo.Module M WITH (NOLOCK) On POA.ModuleId =  M.ModuleId AND M.ModuleName = 'RepairOrder'		
		WHERE POP.RepairOrderId  = @RepairOrderId and isParent = 1 


		UPDATE POP
		SET 
		POP.WorkOrderId = POP1.WorkOrderId,
		POP.SubWorkOrderId = POP1.SubWorkOrderId,
		POP.RepairOrderId = pop1.RepairOrderId,
		POP.SalesOrderId = POP1.SalesOrderId,
		POP.AltEquiPartNumberId = POP1.AltEquiPartNumberId,
		POP.RevisedPartId = POP1.RevisedPartId,
		POP.WorkPerformedId = POP1.WorkPerformedId,
		POP.EstRecordDate	= POP1.EstRecordDate,
		POP.VendorQuoteNoId	= POP1.VendorQuoteNoId,
		POP.VendorQuoteDate	= POP1.VendorQuoteDate,
		POP.ACTailNum = POP1.ACTailNum,
		POP.QuantityReserved = POP1.QuantityOrdered
		FROM 				 
		dbo.RepairOrderPart POP WITH (NOLOCK)
		INNER JOIN dbo.RepairOrderPart POP1 WITH (NOLOCK) ON POP.ParentId = POP1.RepairOrderPartRecordId AND POP.RepairOrderId =  @RepairOrderId;

		UPDATE dbo.RepairOrderPart SET
		   PartNumber =CASE WHEN ROP.IsAsset=1 THEN asi.AssetId ELSE IM.partnumber END,
		   PartDescription =CASE WHEN ROP.IsAsset=1 THEN asi.Description ELSE IM.PartDescription END,
		   AltEquiPartNumber =CASE WHEN ROP.IsAsset=1 THEN (select AssetId from Asset where AssetRecordId=ROP.AltEquiPartNumberId ) ELSE  AIM.PartNumber END,
		   AltEquiPartDescription =CASE WHEN ROP.IsAsset=1 THEN (select Name from Asset where AssetRecordId=ROP.AltEquiPartNumberId ) ELSE AIM.PartDescription END,
		   StockType =CASE WHEN ROP.IsAsset=1 THEN '' ELSE (CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 
							'PMA&DER' 
							WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA' 
							WHEN IM.IsPma = 0 AND IM.IsDER = 1  THEN 'DER' 
							ELSE 'OEM'
							END) END,
		   Manufacturer = MF.[NAME],
		   [Priority] = PR.[Description],
		   Condition = CO.[Description],
		   FunctionalCurrency = CR.Code,
		   ReportCurrency= RC.Code,
		   StockLineNumber =CASE WHEN ROP.IsAsset=1 THEN asi.StklineNumber ELSE  SL.StockLineNumber END,
		   ControlId =CASE WHEN ROP.IsAsset=1 THEN '' else SL.IdNumber END,
		   ControlNumber =CASE WHEN ROP.IsAsset=1 THEN asi.ControlNumber ELSE SL.ControlNumber END,
		   PurchaseOrderNumber= Po.PurchaseOrderNumber, 
		   WorkOrderNo =  WO.WorkOrderNum ,
		   SubWorkOrderNo =SWO.SubWorkOrderNo, 
		   SalesOrderNo = SO.SalesOrderNumber,
		   ItemTypeId =CASE WHEN ROP.IsAsset=1 THEN (select ItemTypeId from ItemType where Name='Asset') ELSE IM.ItemTypeId END,
		   ItemType =CASE WHEN ROP.IsAsset=1 THEN (select Description from ItemType where Name='Asset') ELSE IT.[Description] END,   
		   GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,'')),
		   UnitOfMeasure = UOM.ShortName,
		   --Level1 = RMS.Level1,
		   --Level2 = RMS.Level2,
		   --Level3 = RMS.Level3,
		   --Level4 = RMS.Level4,	
		   RoPartSplitUserType = M.ModuleName, 
		   ROPartSplitUser = CASE WHEN ROP.RoPartSplitUserTypeId = 1 THEN CUST.[Name] 
								  WHEN ROP.RoPartSplitUserTypeId = 2 THEN VEN.VendorName
								  WHEN ROP.RoPartSplitUserTypeId = 9 THEN COM.[Name]						 
							 END,
		   RoPartSplitSiteName =  (CASE WHEN ROPartSplitUserTypeId = 1 THEN
 									(select TOP 1 ISNULL(SiteName,'') from CustomerDomensticShipping WITH (NOLOCK) where CustomerDomensticShippingId = ROP.ROPartSplitSiteId) 
 									WHEN ROPartSplitUserTypeId = 2 THEN
 									(select TOP 1 ISNULL(SiteName,'') from VendorShippingAddress WITH (NOLOCK) where VendorShippingAddressId = ROP.ROPartSplitSiteId) 
 									WHEN ROPartSplitUserTypeId = 9 THEN
 									(select TOP 1 ISNULL(SiteName,'') from LegalEntityShippingAddress WITH (NOLOCK) where LegalEntityShippingAddressId = ROP.ROPartSplitSiteId)
 									END),
		   RevisedPartNumber =CASE WHEN ROP.IsAsset=1 THEN (select AssetId from Asset where AssetRecordId=ROP.RevisedPartId ) ELSE RIM.partnumber END,
		   WorkPerformed = CPT.CapabilityTypeDesc,
		   SerialNumber = CASE WHEN ROP.IsAsset = 1 THEN ASI.SerialNo ELSE SL.SerialNumber END
		FROM  dbo.RepairOrderPart ROP WITH (NOLOCK)
			  --INNER JOIN #RepairOrderPartMSDATA RMS ON RMS.MSID = ROP.ManagementStructureId
			  INNER JOIN RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId=ROP.RepairOrderId	
			  LEFT JOIN ItemMaster IM WITH (NOLOCK) ON ROP.ItemMasterId=IM.ItemMasterId	
			  LEFT JOIN AssetInventory ASI WITH (NOLOCK) ON ROP.ItemMasterId=ASI.AssetRecordId and ROP.StockLineId=ASI.AssetInventoryId	
			  LEFT JOIN Condition CO WITH (NOLOCK) ON CO.ConditionId = ROP.ConditionId
			  INNER JOIN Priority PR WITH (NOLOCK) ON PR.PriorityId = ROP.PriorityId
			  INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId = ROP.FunctionalCurrencyId
			  INNER JOIN Currency RC WITH (NOLOCK) ON RC.CurrencyId = ROP.ReportCurrencyId
			  LEFT JOIN Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = ROP.ManufacturerId
			  INNER JOIN GLAccount    GLA WITH (NOLOCK) ON GLA.GLAccountId = ROP.GlAccountId
			  LEFT JOIN UnitOfMeasure  UOM WITH (NOLOCK)  ON UOM.UnitOfMeasureId = ROP.UOMId
			  LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = ROP.WorkOrderId
			  LEFT JOIN ItemType ITP WITH (NOLOCK) ON ITP.ItemTypeId= ROP.ItemTypeId
			  LEFT JOIN SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = ROP.SubWorkOrderId	  
			  LEFT JOIN SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = ROP.SalesOrderId
			  LEFT JOIN ItemMaster AIM WITH (NOLOCK) ON AIM.ItemMasterId = ROP.AltEquiPartNumberId
			  LEFT JOIN Customer CUST WITH (NOLOCK) ON CUST.CustomerId = ROP.RoPartSplitUserId
			  LEFT JOIN Vendor VEN WITH (NOLOCK) ON VEN.VendorId = ROP.RoPartSplitUserId
			  LEFT JOIN LegalEntity COM WITH (NOLOCK) ON COM.LegalEntityId = ROP.RoPartSplitUserId
			  LEFT JOIN ItemMaster ST WITH (NOLOCK) ON ST.ItemMasterId=ROP.ItemMasterId	
			  LEFT JOIN StockLine SL WITH (NOLOCK) ON SL.StockLineId=ROP.StockLineId	
			  LEFT JOIN Purchaseorder PO WITH (NOLOCK) ON SL.PurchaseOrderId=PO.PurchaseOrderId	
			  LEFT JOIN  ItemType IT WITH (NOLOCK) ON IM.ItemTypeId = IT.ItemTypeId	
			  LEFT JOIN  dbo.Module M WITH (NOLOCK) ON M.ModuleId = ROP.RoPartSplitUserTypeId	
			  LEFT JOIN ItemMaster RIM WITH (NOLOCK) ON ROP.RevisedPartId=RIM.ItemMasterId	
			  --LEFT JOIN WorkPerformed WP WITH (NOLOCK) ON ROP.WorkPerformedId=WP.WorkPerformedId
			  LEFT JOIN CapabilityType CPT WITH (NOLOCK) ON ROP.WorkPerformedId=CPT.CapabilityTypeId

		WHERE ROP.RepairOrderId  = @RepairOrderId 

		DELETE FROM dbo.RepairOrderApproval WHERE
		RepairOrderId =@RepairOrderId and  
		RepairOrderPartId in (select RepairOrderPartRecordId
		from dbo.RepairOrderPart  P WITH (NOLOCK)
		Where RepairOrderId  = @RepairOrderId AND ParentId > 0
		AND (select COUNT(RepairOrderPartRecordId)
		 from dbo.RepairOrderPart WITH (NOLOCK) WHERE RepairOrderPartRecordId = p.ParentId) = 0) and RepairOrderId  = @RepairOrderId;

		DELETE FROM dbo.RepairOrderPart WHERE RepairOrderPartRecordId in (select RepairOrderPartRecordId
		from dbo.RepairOrderPart  P
		Where RepairOrderId  = @RepairOrderId AND ParentId > 0
		AND (select COUNT(RepairOrderPartRecordId)
		from dbo.RepairOrderPart WITH (NOLOCK) WHERE RepairOrderPartRecordId = p.ParentId) = 0) and RepairOrderId  = @RepairOrderId;


		SELECT
		RepairOrderNumber  as value
		FROM dbo.RepairOrder PO WITH (NOLOCK) WHERE RepairOrderId = @RepairOrderId

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateRepairOrderDetail' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''
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