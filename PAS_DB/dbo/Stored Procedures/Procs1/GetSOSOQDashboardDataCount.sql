/*************************************************************           
 ** File:   [GetSOSOQDashboardDataCount]
 ** Author: unknown
 ** Description: 
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	 02/1/2024	  AMIT GHEDIYA		added isperforma Flage for SO
	3    10/16/2024	  Abhishek Jirawla	Implemented the new tables for SalesOrderQuotePart related tables
	4	 12 NOV 2024  HEMANT SALIYA		Verify the count and removed un used code 
	5    11-DEC-2024  RAJESH GAMI       Modified to multyply the Est Revenue and Est Cost for every operation (SO & SOQ) :  Add the separate CTE and using it in JOIN (DeduplicatedRoles)
	6	 30-Jun-2025  Devendra Shekh	Modified(SO Billing Table Changes)
	7	 15/AUG/2026  KISHOR MAKWANA	[PN-17439] - Fixed Amount mismatch between this procedure's dashboard tiles and SOQSODashboardData's "More Info" grid: all 8 Amount calculations (SOQReceived, SOQApprovedInternal, SOQApprovedCustomer, SOApprovedInternal, SOApprovedCustomer, SOFullfilling, SOShipping, SOInvoiced) read Charges/Freight from the cached SalesOrderQuotePartCost/SalesOrderPartCost MiscCharges/Freight columns, which were out of sync with the live line-item data. Now summed directly from SalesOrderQuoteCharges/SalesOrderQuoteFreight/SalesOrderCharges/SalesOrderFreight via OUTER APPLY, matching how SOQSODashboardData.sql computes the grid totals.

************************************************************************/
CREATE PROCEDURE [dbo].[GetSOSOQDashboardDataCount]
	@MasterCompanyId INT = 1,
	@EmployeeId BIGINT = 61,
	@Type varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		DECLARE @Qty AS INT;
		DECLARE @CustomerAffiliation varchar(20);
		IF(@Type = 'internal')
		BEGIN
			SET @CustomerAffiliation = '1';
		END
		ELSE IF(@Type = 'external')
		BEGIN
			SET @CustomerAffiliation = '2';
		END
		ELSE IF(@Type = 'all')
		BEGIN
			SET @CustomerAffiliation = '1,2,3';
		END
		ELSE
		BEGIN
			SET @CustomerAffiliation = '1,2,3';
		END

		DECLARE @SOQReceivedId AS INT =1
		DECLARE @SOQApprovedInternalId AS INT =2
		DECLARE @SOQApprovedCustomerId AS INT =3
		DECLARE @SOApprovedInternalId AS INT =1
		DECLARE @SOApprovedCustomerId AS INT =2
		DECLARE @SOFullfillingStatusId AS INT =10
		DECLARE @SOShippingStatusId AS INT =3
		DECLARE @SOInvoicedStatusId AS INT =3

		DECLARE @SOQReceivedCount AS INT =0
		DECLARE @SOQApprovedInternalCount AS INT =0
		DECLARE @SOQApprovedCustomerCount AS INT =0
		DECLARE @SOApprovedInternalCount AS INT =0
		DECLARE @SOApprovedCustomerCount AS INT =0
		DECLARE @SOFullfillingStatusCount AS INT =0
		DECLARE @SOShippingStatusCount AS INT =0
		DECLARE @SOInvoicedStatusCount AS INT =0

		DECLARE @SOQReceivedAmount AS DECIMAL(20, 2);
		DECLARE @SOQApprovedInternalAmount AS DECIMAL(20, 2);
		DECLARE @SOQApprovedCustomerAmount AS DECIMAL(20, 2);
		DECLARE @SOApprovedInternalAmount AS DECIMAL(20, 2);
		DECLARE @SOApprovedCustomerAmount AS DECIMAL(20, 2);
		DECLARE @SOFullfillingAmount AS DECIMAL(20, 2);
		DECLARE @SOShippingAmount AS DECIMAL(20, 2);
		DECLARE @SOInvoicedAmount AS DECIMAL(20, 2);
		DECLARE @SOQMSModuleID INT = 18;
		DECLARE @SOMSModuleID INT = 17;
		DECLARE @salesOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder');

		IF OBJECT_ID(N'tempdb..#tmpSOQUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpSOQUserRole
		END
		IF OBJECT_ID(N'tempdb..#tmpSOUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpSOUserRole
		END

		SELECT * INTO #tmpSOQUserRole FROM (SELECT DISTINCT
							MSD.ReferenceID,
							RMS.EntityStructureId
						FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
						INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) 
							ON MSD.EntityMsId = RMS.EntityStructureId
						INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) 
							ON EUR.RoleId = RMS.RoleId
						WHERE MSD.ModuleID = @SOQMSModuleID AND EUR.EmployeeId = @EmployeeId) AS soqUserRole
		
		SELECT * INTO #tmpSOUserRole FROM (SELECT DISTINCT
							MSD.ReferenceID,
							RMS.EntityStructureId
						FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
						INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) 
							ON MSD.EntityMsId = RMS.EntityStructureId
						INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) 
							ON EUR.RoleId = RMS.RoleId
						WHERE MSD.ModuleID = @SOMSModuleID AND EUR.EmployeeId = @EmployeeId) AS soUserRole


		SELECT  @SOQReceivedCount=count(SOQ.SalesOrderQuoteId)  FROM 
				DBO.SalesOrderQuote SOQ WITH (NOLOCK)				
				INNER JOIN #tmpSOQUserRole DR ON DR.ReferenceID = SOQ.SalesOrderQuoteId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = SOQ.CustomerId
			WHERE  (ISNULL(SOQ.IsDeleted, 0) = 0) and (SOQ.StatusId =@SOQReceivedId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND SOQ.MasterCompanyId = @MasterCompanyId
			GROUP BY SOQ.StatusId

		SELECT @SOQReceivedAmount = SUM(ISNULL(SOQPC.NetSaleAmount,0))
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderQuote SOQ WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
				LEFT JOIN DBO.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId=SOQP.SalesOrderQuotePartId and ISNULL(SOQPC.IsDeleted, 0)=0
				INNER JOIN #tmpSOQUserRole DR ON DR.ReferenceID = SOQ.SalesOrderQuoteId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = SOQ.CustomerId
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderQuoteCharges WITH (NOLOCK) WHERE SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderQuoteFreight WITH (NOLOCK) WHERE SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId) BFF
			WHERE  (ISNULL(SOQ.IsDeleted, 0) = 0) and (ISNULL(SOQP.IsDeleted, 0) = 0) and (SOQ.StatusId =@SOQReceivedId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND SOQ.MasterCompanyId = @MasterCompanyId
			GROUP BY SOQ.StatusId

	   SELECT  @SOQApprovedInternalCount=count(distinct PO.SalesOrderQuoteId)  FROM 
				DBO.SalesOrderQuote PO WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = PO.SalesOrderQuoteId
				INNER JOIN #tmpSOQUserRole DR ON DR.ReferenceID = PO.SalesOrderQuoteId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId AND SOQAP.InternalStatusId=4
			WHERE  ISNULL(PO.IsDeleted, 0) = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId

	  SELECT @SOQApprovedInternalAmount = SUM(SOQPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderQuotePartV1 POP WITH (NOLOCK) INNER JOIN DBO.SalesOrderQuote PO WITH (NOLOCK) ON PO.SalesOrderQuoteId = POP.SalesOrderQuoteId
				LEFT JOIN DBO.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId=POP.SalesOrderQuotePartId and SOQPC.IsDeleted=0
				INNER JOIN #tmpSOQUserRole DR ON DR.ReferenceID = PO.SalesOrderQuoteId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = POP.SalesOrderQuotePartId AND SOQAP.InternalStatusId=4
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderQuoteCharges WITH (NOLOCK) WHERE SalesOrderQuotePartId = POP.SalesOrderQuotePartId) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderQuoteFreight WITH (NOLOCK) WHERE SalesOrderQuotePartId = POP.SalesOrderQuotePartId) BFF
			WHERE ISNULL(PO.IsDeleted, 0) = 0 and ISNULL(POP.IsDeleted, 0) = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId

	 SELECT  @SOQApprovedCustomerCount=count(distinct PO.SalesOrderQuoteId)  FROM 
				DBO.SalesOrderQuote PO WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = PO.SalesOrderQuoteId
				INNER JOIN #tmpSOQUserRole DR ON DR.ReferenceID = PO.SalesOrderQuoteId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId AND SOQAP.CustomerStatusId=4
			WHERE  ISNULL(PO.IsDeleted, 0) = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId

   SELECT @SOQApprovedCustomerAmount = SUM(SOQPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderQuotePartV1 POP WITH (NOLOCK) INNER JOIN DBO.SalesOrderQuote PO WITH (NOLOCK) ON PO.SalesOrderQuoteId = POP.SalesOrderQuoteId
				LEFT JOIN DBO.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId=POP.SalesOrderQuotePartId and SOQPC.IsDeleted=0
	   			INNER JOIN #tmpSOQUserRole DR ON DR.ReferenceID = PO.SalesOrderQuoteId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = POP.SalesOrderQuotePartId AND SOQAP.CustomerStatusId=4
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderQuoteCharges WITH (NOLOCK) WHERE SalesOrderQuotePartId = POP.SalesOrderQuotePartId AND ISNULL(IsDeleted, 0) = 0) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderQuoteFreight WITH (NOLOCK) WHERE SalesOrderQuotePartId = POP.SalesOrderQuotePartId AND ISNULL(IsDeleted, 0) = 0) BFF
			WHERE ISNULL(PO.IsDeleted, 0) = 0 and ISNULL(POP.IsDeleted, 0) = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId
				
	   SELECT @SOApprovedInternalCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO WITH (NOLOCK)
			   INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderId = RO.SalesOrderId
			   INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
			   INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = SOP.SalesOrderPartId AND SOAPR.InternalStatusId=4
		WHERE ISNULL(RO.IsDeleted, 0) = 0 AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
			   AND RO.MasterCompanyId = @MasterCompanyId

	   
	   SELECT @SOApprovedInternalAmount = SUM(SOPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderPartV1 ROP WITH (NOLOCK) INNER JOIN DBO.SalesOrder RO WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
				LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId=ROP.SalesOrderPartId and SOPC.IsDeleted=0
				INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = ROP.SalesOrderPartId AND SOAPR.InternalStatusId=4
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFF
		WHERE ISNULL(RO.IsDeleted, 0) = 0  and ISNULL(ROP.IsDeleted, 0) = 0  AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId

	  SELECT @SOApprovedCustomerCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO WITH (NOLOCK)
			   INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderId = RO.SalesOrderId
			    INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
			   INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = SOP.SalesOrderPartId AND SOAPR.CustomerStatusId=4
		WHERE ISNULL(RO.IsDeleted, 0) = 0  AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId

	  SELECT @SOApprovedCustomerAmount = SUM(SOPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderPartV1 ROP WITH (NOLOCK) INNER JOIN DBO.SalesOrder RO WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
				LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId=ROP.SalesOrderPartId and SOPC.IsDeleted=0
				 INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = ROP.SalesOrderPartId AND SOAPR.CustomerStatusId=4
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFF
				Where ISNULL(RO.IsDeleted, 0) = 0  and ISNULL(ROP.IsDeleted, 0) = 0  AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId
	
	SELECT @SOFullfillingStatusCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO WITH (NOLOCK)
			   INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderId = RO.SalesOrderId
			    INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
	WHERE ISNULL(RO.IsDeleted, 0) = 0 and (RO.StatusId = @SOFullfillingStatusId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId


	 SELECT @SOFullfillingAmount = SUM(SOPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderPartV1 ROP WITH (NOLOCK) INNER JOIN DBO.SalesOrder RO WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
				LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId=ROP.SalesOrderPartId and SOPC.IsDeleted=0
				INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId			
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFF
	WHERE ISNULL(RO.IsDeleted, 0) = 0 and ISNULL(ROP.IsDeleted, 0) = 0 and (RO.StatusId = @SOFullfillingStatusId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId 

	SELECT @SOShippingStatusCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO WITH (NOLOCK)
			   INNER JOIN DBO.SalesOrderPartV1 ROP WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
			   INNER JOIN DBO.SalesOrderApproval SOAPR WITH (NOLOCK) ON RO.SalesOrderId = SOAPR.SalesOrderId AND ROP.SalesOrderPartId = SOAPR.SalesOrderPartId AND SOAPR.CustomerStatusId=2
			    INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
	WHERE (ISNULL(RO.IsDeleted, 0) = 0 AND RO.StatusId != 2)
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From dbo.SalesOrderShippingItem WITH (NOLOCK))

	 SELECT @SOShippingAmount = SUM(SOPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrder RO WITH (NOLOCK) INNER JOIN DBO.SalesOrderPartV1 ROP WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
				LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId=ROP.SalesOrderPartId and SOPC.IsDeleted=0
				INNER JOIN DBO.SalesOrderApproval SOAPR WITH (NOLOCK) ON RO.SalesOrderId = SOAPR.SalesOrderId AND ROP.SalesOrderPartId = SOAPR.SalesOrderPartId AND SOAPR.CustomerStatusId=2
				INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFF
	WHERE ISNULL(RO.IsDeleted, 0) = 0 and ISNULL(ROP.IsDeleted, 0) = 0 AND RO.StatusId != 2
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From dbo.SalesOrderShippingItem WITH (NOLOCK))

	SELECT @SOInvoicedStatusCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO WITH (NOLOCK)
			   INNER JOIN DBO.SalesOrderPartV1 ROP WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
			   INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			   INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId
			   INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
	WHERE ISNULL(RO.IsDeleted, 0) = 0
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND ROP.SalesOrderPartId NOT IN(select SubReferenceId From dbo.BillingInvoicingItems WITH (NOLOCK) WHERE ISNULL(IsPerformaInvoice,0) = 0 AND ModuleId = @salesOrderModuleId)


	 SELECT @SOInvoicedAmount = SUM(SOPC.NetSaleAmount)
				+ SUM(ISNULL(BFC.Charges,0))
				+ SUM(ISNULL(BFF.Freight,0)) FROM
				DBO.SalesOrderPartV1 ROP WITH (NOLOCK) INNER JOIN DBO.SalesOrder RO WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
				LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId=ROP.SalesOrderPartId and SOPC.IsDeleted=0
			    INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON ROP.SalesOrderPartId = SOSI.SalesOrderPartId
				INNER JOIN #tmpSOUserRole DR ON DR.ReferenceID = RO.SalesOrderId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				OUTER APPLY (SELECT SUM(BillingAmount) AS Charges FROM dbo.SalesOrderCharges WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFC
				OUTER APPLY (SELECT SUM(BillingAmount) AS Freight FROM dbo.SalesOrderFreight WITH (NOLOCK) WHERE SalesOrderPartId = ROP.SalesOrderPartId AND ISNULL(IsDeleted, 0) = 0) BFF
	WHERE ISNULL(RO.IsDeleted, 0) = 0 and ISNULL(ROP.IsDeleted, 0) = 0
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND ROP.SalesOrderPartId NOT IN(select SubReferenceId From dbo.BillingInvoicingItems WITH (NOLOCK) WHERE ISNULL(IsPerformaInvoice,0) = 0 AND ModuleId = @salesOrderModuleId)

		SELECT ISNULL(@SOQReceivedCount, 0) AS 'SOQReceivedCount', ISNULL(@SOQApprovedInternalCount, 0) AS 'SOQApprovedInternalCount', ISNULL(@SOQApprovedCustomerCount, 0) AS 'SOQApprovedCustomerCount', 
		ISNULL(@SOApprovedInternalCount, 0) AS 'SOApprovedInternalCount', ISNULL(@SOApprovedCustomerCount, 0) AS 'SOApprovedCustomerCount', ISNULL(@SOFullfillingStatusCount, 0) AS 'SOFullfillingStatusCount',
		 ISNULL(@SOShippingStatusCount, 0) AS 'SOShippingStatusCount', ISNULL(@SOInvoicedStatusCount, 0) AS 'SOInvoicedStatusCount',
		ISNULL(@SOQReceivedAmount, 0) AS 'SOQReceivedAmount',
		ISNULL(@SOQApprovedInternalAmount, 0) AS 'SOQApprovedInternalAmount', ISNULL(@SOQApprovedCustomerAmount, 0) AS 'SOQApprovedCustomerAmount',
		ISNULL(@SOApprovedInternalAmount, 0) AS 'SOApprovedInternalAmount',ISNULL(@SOApprovedCustomerAmount, 0) AS 'SOApprovedCustomerAmount',
		ISNULL(@SOFullfillingAmount, 0) AS 'SOFullfillingAmount',ISNULL(@SOShippingAmount, 0) AS 'SOShippingAmount',ISNULL(@SOInvoicedAmount, 0) AS 'SOInvoicedAmount'
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPORODashboardDataCount' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '
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