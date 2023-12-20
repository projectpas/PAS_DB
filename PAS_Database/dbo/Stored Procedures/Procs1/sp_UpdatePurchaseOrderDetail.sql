/*************************************************************           
 ** File:   [sp_UpdatePurchaseOrderDetail]           
 ** Author:   -
 ** Description: This stored procedure is used to update different module data based on purchase order part 
 ** Purpose:         
 ** Date:   10/19/2023        
          
 ** PARAMETERS:           
 @PurchaseOrderId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/19/2023   Vishal Suthar		Added history
	
 EXEC sp_UpdatePurchaseOrderDetail 214
**************************************************************/
CREATE   Procedure [dbo].[sp_UpdatePurchaseOrderDetail]
	@PurchaseOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
		DECLARE @StockType int = 1;
		DECLARE @NonStockType int = 2;
		DECLARE @AssetType int = 11;

		UPDATE dbo.WorkOrderMaterials
		SET 
		QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = CASE WHEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) < ISNULL(PP.Qty, 0)
		THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) 
		ELSE ISNULL(PP.Qty, 0)
		END, PONum = P.PurchaseOrderNumber ,POId = pop.PurchaseOrderId ,PONextDlvrDate = pop.EstDeliveryDate
		from dbo.PurchaseOrderPart POP
		INNER JOIN dbo.WorkOrderMaterials WOM ON WOM.WorkOrderId = POP.WorkOrderId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId
		JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId
		LEFT JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId
		where POP.PurchaseOrderId = @PurchaseOrderId  AND POP.isParent = 1 AND POP.WorkOrderId > 0 and ISNULL(POP.SubWorkOrderId,0)  = 0

		UPDATE dbo.WorkOrderMaterialsKit
		SET 
		QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = CASE WHEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) < ISNULL(PP.Qty, 0)
		THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) 
		ELSE ISNULL(PP.Qty, 0)
		END, PONum = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.EstDeliveryDate
		from dbo.PurchaseOrderPart POP
		INNER JOIN dbo.WorkOrderMaterialsKit WOM ON WOM.WorkOrderId = POP.WorkOrderId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId
		JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId
		LEFT JOIN dbo.PurchaseOrderPartReference PP ON PP.PurchaseOrderId = POP.PurchaseOrderId
		where POP.PurchaseOrderId = @PurchaseOrderId  AND POP.isParent = 1 AND POP.WorkOrderId > 0 and ISNULL(POP.SubWorkOrderId,0)  = 0

		UPDATE dbo.SubWorkOrderMaterials
		SET 
		QtyOnOrder = POP.QuantityOrdered, QtyOnBkOrder = POP.QuantityBackOrdered, PONum = P.PurchaseOrderNumber ,POId = pop.PurchaseOrderId ,PONextDlvrDate = pop.NeedByDate
		from dbo.PurchaseOrderPart POP
		INNER JOIN dbo.SubWorkOrderMaterials WOM ON WOM.SubWorkOrderId = POP.SubWorkOrderId and WOM.ConditionCodeId = POP.ConditionId and wom.ItemMasterId = pop.ItemMasterId
		JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId
		where POP.PurchaseOrderId = @PurchaseOrderId  AND POP.isParent = 1 AND POP.SubWorkOrderId > 0 

		UPDATE dbo.SalesOrderPart
		SET 
		--Qty = POP.QuantityOrdered, 
		PONumber = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.NeedByDate
		from dbo.PurchaseOrderPart POP
		INNER JOIN dbo.SalesOrderPart SOP ON SOP.SalesOrderId = POP.SalesOrderId and SOP.ConditionId = POP.ConditionId and SOP.ItemMasterId = POP.ItemMasterId
		JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId
		where POP.PurchaseOrderId = @PurchaseOrderId  AND POP.isParent = 1 AND POP.SalesOrderId > 0

		UPDATE dbo.ExchangeSalesOrderPart
		SET 
		--Qty = POP.QuantityOrdered, 
		PONumber = P.PurchaseOrderNumber, POId = pop.PurchaseOrderId, PONextDlvrDate = pop.NeedByDate
		from dbo.PurchaseOrderPart POP
		INNER JOIN dbo.ExchangeSalesOrderPart SOP ON SOP.ExchangeSalesOrderId = POP.ExchangeSalesOrderId and SOP.ConditionId = POP.ConditionId and SOP.ItemMasterId = POP.ItemMasterId
		JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId
		where POP.PurchaseOrderId = @PurchaseOrderId  AND POP.isParent = 1 AND POP.ExchangeSalesOrderId > 0

		UPDATE PO SET
		PO.StatusId = (SELECT POStatusID FROM dbo.POStatus Where IsActive = 1 and IsDeleted = 0  and Memo = 'Fulfilling' ),
		PO.ApproverId = ISNULL((select TOP 1 PA.ApprovedById from dbo.PurchaseOrderApproval PA WITH (NOLOCK) INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE PurchaseOrderID = @PurchaseOrderId ORDER BY ApprovedDate DESC),0),
		PO.DateApproved = (select TOP 1 PA.ApprovedDate from dbo.PurchaseOrderApproval PA WITH (NOLOCK)
							INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE PurchaseOrderID = @PurchaseOrderId ORDER BY ApprovedDate DESC)
		FROM dbo.PurchaseOrder PO WITH (NOLOCK)
		WHERE PurchaseOrderID = @PurchaseOrderId
		AND 
		ISNULL((select Count(PA.PurchaseOrderApprovalId) 
				from dbo.PurchaseOrderApproval PA WITH (NOLOCK) INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK)
					 ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
					 INNER JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId = PA.PurchaseOrderPartId
					 WHERE POP.PurchaseOrderID = @PurchaseOrderId),0) = ISNULL((select Count(PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart  WHERE  PurchaseOrderID = @PurchaseOrderId and isParent = 1),0)
		AND 
		(select Count(PA.PurchaseOrderApprovalId) from 
			dbo.PurchaseOrderApproval PA WITH (NOLOCK) INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK) 
				ON PA.StatusId = APS.ApprovalStatusId  AND APS.Name =  'Approved'
		  INNER JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId = PA.PurchaseOrderPartId
				WHERE POP.PurchaseOrderID = @PurchaseOrderId) > 0
		AND
		(SELECT COUNT(POA.AddressId)  FROM  dbo.AllAddress POA WITH (NOLOCK)  
		   INNER JOIN dbo.Module M WITH (NOLOCK) ON POA.ModuleId = POA.ModuleId
		  WHERE POA.ReffranceId = @PurchaseOrderId
				 AND POA.IsShippingAdd = 1  AND M.ModuleName = 'PurchaseOrder')  > 0
		AND
		(SELECT COUNT(POA.AddressId)  FROM  dbo.AllAddress POA  WITH (NOLOCK)
		 INNER JOIN dbo.Module M WITH (NOLOCK) ON POA.ModuleId = POA.ModuleId
		  WHERE POA.ReffranceId = @PurchaseOrderId
				 AND POA.IsShippingAdd = 0 AND M.ModuleName = 'PurchaseOrder')  > 0

		UPDATE dbo.PurchaseOrderApproval SET ApprovedById = null , ApprovedDate = null , ApprovedByName = null
		Where PurchaseOrderId = @PurchaseOrderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Approved') 


		UPDATE dbo.PurchaseOrderApproval SET RejectedBy = null , RejectedDate =  null , RejectedByName = null
		Where PurchaseOrderId = @PurchaseOrderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Rejected') 

		UPDATE dbo.PurchaseOrderApproval
		SET ApprovedByName = AE.FirstName + ' ' + AE.LastName,
			RejectedByName = RE.FirstName + ' ' + RE.LastName,
			StatusName = ASS.Description,
			InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM dbo.PurchaseOrderApproval PA
			 LEFT JOIN dbo.Employee AE on PA.ApprovedById = AE.EmployeeId
			 LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = PA.InternalSentToId
			 LEFT JOIN dbo.Employee RE on PA.RejectedBy = RE.EmployeeId
			 LEFT JOIN dbo.ApprovalStatus ASS on PA.StatusId = ASS.ApprovalStatusId

		--DECLARE @MSID as bigint
		--DECLARE @Level1 as varchar(200)
		--DECLARE @Level2 as varchar(200)
		--DECLARE @Level3 as varchar(200)
		--DECLARE @Level4 as varchar(200)

		--IF OBJECT_ID(N'tempdb..#PurchaseOrderPartMSDATA') IS NOT NULL
		--BEGIN
		--DROP TABLE #PurchaseOrderPartMSDATA 
		--END
		--CREATE TABLE #PurchaseOrderPartMSDATA
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
		--  SELECT PO.ManagementStructureId FROM dbo.PurchaseOrder PO Where PO.PurchaseOrderId = @PurchaseOrderId

		--INSERT INTO #MSDATA (MSID)
		--  SELECT DISTINCT POP.ManagementStructureId
		--	 FROM dbo.PurchaseOrderPart POP Where POP.PurchaseOrderId = @PurchaseOrderId
		--		  AND POP.ManagementStructureId 
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

		--INSERT INTO #PurchaseOrderPartMSDATA
		--			(MSID, Level1,Level2,Level3,Level4)
		--	  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
		--SET @LoopID = @LoopID - 1;
		--END 

 
		UPDATE PO SET
		PO.[Priority] = PR.Description,
		PO.VendorName = V.VendorName,
		PO.VendorCode = V.VendorCode,
		PO.VendorContact = ISNULL(C.FirstName,'') + ' ' + ISNULL(C.LastName,''),
		PO.VendorContactPhone = ISNULL(C.WorkPhone,'') + '-' + ISNULL(C.WorkPhoneExtn,''),
		PO.VendorContactEmail = ISNULL(C.Email,''),
		PO.Terms = CT.Name,
		PO.CreditLimit = ISNULL(V.CreditLimit,0.00),
		PO.Status = PS.Description,
		PO.Requisitioner = ISNULL(e.FirstName,'') + ' ' + ISNULL(e.LastName,''),
		--PO.Level1 = PMS.Level1,
		--PO.Level2 = PMS.Level2,
		--PO.Level3 = PMS.Level3,
		--PO.Level4 = PMS.Level4,
		PO.ApprovedBy = ISNULL(AP.FirstName,'') + ' ' + ISNULL(AP.LastName,'')
		FROM dbo.PurchaseOrder PO WITH (NOLOCK)
		--LEFT JOIN #PurchaseOrderPartMSDATA PMS ON PMS.MSID = PO.ManagementStructureId
		LEFT JOIN dbo.POStatus PS WITH (NOLOCK) on PS.POStatusId = PO.StatusId
		LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = PO.VendorId
		LEFT JOIN dbo.VendorContact VC WITH (NOLOCK) ON VC.VendorContactId = PO.VendorContactId
		LEFT JOIN dbo.Contact C WITH (NOLOCK) ON  VC.ContactId =  C.ContactId
		LEFT JOIN dbo.CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId = PO.CreditTermsId
		LEFT JOIN dbo.Employee E WITH (NOLOCK) on PO.RequestedBy =  E.EmployeeId
		LEFT JOIN dbo.Employee AP WITH (NOLOCK) ON PO.ApproverId = AP.EmployeeId
		LEFT JOIN Priority PR WITH (NOLOCK)  ON  PR.PriorityId = PO.PriorityId
		WHERE PO.PurchaseOrderID = @PurchaseOrderId

		UPDATE POP SET 
		POP.POPartSplitUserTypeId = POA.UserType,
		POPartSplitUserType = POA.UserTypeName,
		POP.POPartSplitUserId = POA.UserId,
		POP.POPartSplitUser = POA.UserName,
		POP.POPartSplitSiteId = POA.SiteId,
		POP.POPartSplitSiteName = POA.SiteName,
		POP.POPartSplitAddressId = POA.AddressId,
		POP.POPartSplitAddress1 =  POA.Line1,
		POP.POPartSplitAddress2 =  POA.Line2,
		POP.POPartSplitAddress3=  POA.Line3,
		POP.POPartSplitCity=  POA.City,
		POP.POPartSplitState=  POA.StateOrProvince,
		POP.POPartSplitPostalCode=  POA.PostalCode,
		POP.POPartSplitCountryId =  POA.CountryId,
		POP.POPartSplitCountryName =  POA.Country
		FROM  dbo.PurchaseOrderPart POP WITH (NOLOCK)
		INNER JOIN dbo.AllAddress  POA WITH (NOLOCK) 
				 ON POA.ReffranceId = POP.PurchaseOrderId 
				 AND POA.IsShippingAdd = 1
		INNER JOIN dbo.Module M WITH (NOLOCK) On POA.ModuleId =  M.ModuleId AND M.ModuleName = 'PurchaseOrder'		
		WHERE POP.PurchaseOrderId  = @PurchaseOrderId and isParent = 1 

		UPDATE POP
		SET 
		POP.WorkOrderId = POP1.WorkOrderId,
		POP.SubWorkOrderId = POP1.SubWorkOrderId,
		POP.RepairOrderId = pop1.RepairOrderId,
		POP.SalesOrderId = POP1.SalesOrderId,
		POP.AltEquiPartNumberId = POP1.AltEquiPartNumberId,
		POP.EstDeliveryDate = POP1.EstDeliveryDate,
		POP.ExchangeSalesOrderId = POP1.ExchangeSalesOrderId
		FROM 
		dbo.PurchaseOrderPart POP
		INNER JOIN dbo.PurchaseOrderPart POP1 ON POP.ParentId = POP1.PurchaseOrderPartRecordId AND POP.PurchaseOrderId =  @PurchaseOrderId 
				
		UPDATE dbo.PurchaseOrderPart
		SET
		   PartNumber =  CASE WHEN POP.ItemTypeId = @StockType THEN IM.partnumber WHEN POP.ItemTypeId = @NonStockType THEN IMN.PartNumber WHEN POP.ItemTypeId = @AssetType THEN AST.AssetId END,
		   PartDescription = CASE WHEN POP.ItemTypeId = @StockType THEN IM.PartDescription WHEN POP.ItemTypeId = @NonStockType THEN IMN.PartDescription WHEN POP.ItemTypeId = @AssetType THEN AST.[Description] END,
		   AltEquiPartNumber = CASE WHEN POP.ItemTypeId = @StockType THEN AIM.PartNumber WHEN POP.ItemTypeId = @NonStockType THEN '' WHEN POP.ItemTypeId = @AssetType THEN AAST.AssetId END,
		   AltEquiPartDescription = CASE WHEN POP.ItemTypeId = @StockType THEN AIM.PartDescription WHEN POP.ItemTypeId = @NonStockType THEN '' WHEN POP.ItemTypeId = @AssetType THEN  AAST.[Description] END, 
		   StockType = CASE WHEN POP.ItemTypeId = @StockType THEN (CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 
							'PMA&DER' 
							WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA' 
							WHEN IM.IsPma = 0 AND IM.IsDER = 1  THEN 'DER' 
							ELSE 'OEM'
							END) ELSE '' END,
		   Manufacturer = MF.[NAME],
		   [Priority] = PR.[Description],
		   Condition = CO.[Description],
		   FunctionalCurrency = CR.Code,
		   ReportCurrency= RC.Code,
		   WorkOrderNo =  WO.WorkOrderNum ,
		   SubWorkOrderNo =SWO.SubWorkOrderNo,
		   ReapairOrderNo = RO.RepairOrderNumber,
		   SalesOrderNo = SO.SalesOrderNumber,
		   --ItemTypeId = IM.ItemTypeId,
		   ItemType = IT.[Description],   
		   GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,'')),
		   UnitOfMeasure = UOM.ShortName,
		   --Level1 = PMS.Level1,
		   --Level2 = PMS.Level2,
		   --Level3 = PMS.Level3,
		   --Level4 = PMS.Level4,
		   POPartSplitUserType = M.ModuleName,
		   POPartSplitUser = CASE WHEN POP.POPartSplitUserTypeId = 1 THEN CUST.[Name] 
								  WHEN POP.POPartSplitUserTypeId = 2 THEN VEN.VendorName
								  WHEN POP.POPartSplitUserTypeId = 9 THEN COM.[Name]						 
							 END,
		   POPartSplitSiteName =  (CASE WHEN POPartSplitUserTypeId = 1 THEN
									(select TOP 1 ISNULL(SiteName,'') from CustomerDomensticShipping where CustomerDomensticShippingId = POP.POPartSplitSiteId) 
									WHEN POPartSplitUserTypeId = 2 THEN
									(select TOP 1 ISNULL(SiteName,'') from VendorShippingAddress where VendorShippingAddressId = POP.POPartSplitSiteId) 
									WHEN POPartSplitUserTypeId = 9 THEN
									(select TOP 1 ISNULL(SiteName,'') from LegalEntityShippingAddress where LegalEntityShippingAddressId = POP.POPartSplitSiteId)
									END),  
			DiscountPercentValue = PV.[DiscontValue],
			ExchangeSalesOrderNo = ExchSO.ExchangeSalesOrderNumber
		FROM  dbo.PurchaseOrderPart POP WITH (NOLOCK)
			  --INNER JOIN #PurchaseOrderPartMSDATA PMS ON PMS.MSID = POP.ManagementStructureId			  
			  INNER JOIN dbo.Priority PR WITH (NOLOCK) ON PR.PriorityId = POP.PriorityId
			  INNER JOIN dbo.Currency CR WITH (NOLOCK) ON CR.CurrencyId = POP.FunctionalCurrencyId
			  INNER JOIN dbo.Currency RC WITH (NOLOCK) ON RC.CurrencyId = POP.ReportCurrencyId
			  LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = POP.ManufacturerId
			  LEFT JOIN dbo.ItemMaster IM  WITH (NOLOCK) ON POP.ItemMasterId = IM.ItemMasterId
			  LEFT JOIN dbo.Asset AST  WITH (NOLOCK) ON POP.ItemMasterId = AST.AssetRecordId	
			  LEFT JOIN dbo.ItemMasterNonStock IMN WITH (NOLOCK) ON POP.ItemMasterId = IMN.MasterPartId	
			  LEFT JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = POP.GlAccountId
			  LEFT JOIN dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = POP.ConditionId
			  LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = POP.UOMId			  
			  LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = POP.WorkOrderId
			  LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = POP.SubWorkOrderId
			  LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = POP.RepairOrderId
			  LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = POP.SalesOrderId
			  LEFT JOIN dbo.ItemMaster AIM WITH (NOLOCK) ON AIM.ItemMasterId = POP.AltEquiPartNumberId
			  LEFT JOIN dbo.Asset AAST WITH (NOLOCK) ON AAST.AssetRecordId = POP.AltEquiPartNumberId 
			  LEFT JOIN dbo.Customer CUST WITH (NOLOCK) ON CUST.CustomerId = POP.POPartSplitUserId
			  LEFT JOIN dbo.Vendor VEN WITH (NOLOCK) ON VEN.VendorId = POP.POPartSplitUserId
			  LEFT JOIN dbo.LegalEntity COM WITH (NOLOCK) ON COM.LegalEntityId =POP.POPartSplitUserId
			  LEFT JOIN  dbo.ItemType IT WITH (NOLOCK) ON IT.ItemTypeId = POP.ItemTypeId	
			  LEFT JOIN  dbo.Module M WITH (NOLOCK) ON M.ModuleId = POP.POPartSplitUserTypeId	
			  LEFT JOIN  dbo.[Discount] PV WITH (NOLOCK) ON POP.DiscountPercent = PV.DiscountId	
			  LEFT JOIN dbo.ExchangeSalesOrder ExchSO WITH (NOLOCK) ON ExchSO.ExchangeSalesOrderId = POP.ExchangeSalesOrderId
		WHERE POP.PurchaseOrderId  = @PurchaseOrderId 


		DELETE FROM dbo.PurchaseOrderApproval WHERE
		PurchaseOrderID =@PurchaseOrderId and  
		PurchaseOrderPartId in (select PurchaseOrderPartRecordId
		from dbo.PurchaseOrderPart  P
		Where PurchaseOrderId  = @PurchaseOrderId AND ParentId > 0
		AND (select COUNT(PurchaseOrderPartRecordId)
		 from dbo.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = p.ParentId) = 0) and PurchaseOrderId  = @PurchaseOrderId

		DELETE FROM dbo.PurchaseOrderPart WHERE PurchaseOrderPartRecordId in (select PurchaseOrderPartRecordId
		from dbo.PurchaseOrderPart  P
		Where PurchaseOrderId  = @PurchaseOrderId AND ParentId > 0
		AND (select COUNT(PurchaseOrderPartRecordId)
		 from dbo.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = p.ParentId) = 0) and PurchaseOrderId  = @PurchaseOrderId

		SELECT
		PurchaseOrderNumber as value
		FROM dbo.PurchaseOrder PO WITH (NOLOCK) WHERE PurchaseOrderID = @PurchaseOrderId	

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_UpdatePurchaseOrderDetail' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
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