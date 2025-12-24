/*************************************************************           
 ** File:  [usp_GetRFQPOAndPODocumentsByReferenceId]  
 ** Author:   Devendra Shekh
 ** Description: Retrieve Documents list based on refferenceId
 ** Purpose:         
 ** Date:   14-Nov-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date					Author		     		Change Description            
 ** --    --------				-------					-------------------------------          
    1     14-Nov-2025			Devendra Shekh			Created
	2	  04-Dec-2025			Ayushi Patel			Filtered documents by AiIntegrationSetting DocumentType
	3     05-12-2025			Ayushi Patel			Get Document From RFQ PO and PO by SalesOrderQuoteId
	4	  09-Dec-2025			Ayushi Patel			Get the field DocumentType (name)
	5	  19-Dec-2025			AMit Ghediya			Get Email doc.
EXEC [usp_GetRFQPOAndPODocumentsByReferenceId]  1407,1,46
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_GetRFQPOAndPODocumentsByReferenceId]
	@ReferenceId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL,
	@ModuleId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 

		DECLARE @SOQ_ModuleId INT = 0,
				@PO_ModuleId INT = 0,
				@PO_DocModuleId INT = 0,
				@VRFQPO_DocModuleId INT = 0,
				@SOQ_DocModuleId INT = 0,
				@PORerenceIds VARCHAR(MAX) = '',
				@RFQPORerenceIds VARCHAR(MAX) = '',
				@EmailDocRerenceIds VARCHAR(MAX) = '',
				@EmailDoc_ModuleId INT = 0;

		SELECT @PO_DocModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'PurchaseOrder';
		SELECT @VRFQPO_DocModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'VendorRFQPurchaseOrder';
		SELECT @SOQ_DocModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'SalesQuote';
		SELECT @SOQ_ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';
		SELECT @PO_ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';
		SELECT @EmailDoc_ModuleId = [AttachmentModuleId] FROM [dbo].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'EmailDocuments';;

		IF(@ModuleId = @SOQ_DocModuleId)
		BEGIN
			;WITH Result AS (
				SELECT DISTINCT VRFQ.ReferenceId
				FROM [dbo].[ILSRFQPart] PT WITH(NOLOCK)
				INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON PT.CustomerRfqId = RFQ.CustomerRfqId
				INNER JOIN [dbo].[VendorRFQPart] VRFQ WITH(NOLOCK) ON PT.ILSRFQDetailId = VRFQ.ILSRFQDetailId
				WHERE RFQ.ModuleId = @SOQ_ModuleId AND RFQ.ReferenceId = @ReferenceId AND VRFQ.ModuleId = @PO_ModuleId AND PT.MasterCompanyId = @MasterCompanyId

				UNION

				SELECT DISTINCT PO.PurchaseOrderId AS ReferenceId
				FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK)
				INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId
				WHERE PO.MasterCompanyId = @MasterCompanyId AND POP.SalesOrderQuoteId = @ReferenceId

			)
			SELECT @PORerenceIds = STRING_AGG([ReferenceId], ',') FROM Result;
			 
			;WITH VRFQResult AS (
				SELECT DISTINCT VPO.VendorRFQPurchaseOrderId AS [ReferenceId]
				FROM [dbo].[VendorRFQPurchaseOrder] VPO WITH(NOLOCK)
				INNER JOIN [dbo].[VendorRFQPurchaseOrderPart] VPOP WITH(NOLOCK) ON VPO.VendorRFQPurchaseOrderId = VPOP.VendorRFQPurchaseOrderId
				WHERE VPO.MasterCompanyId = @MasterCompanyId AND 
				((VPOP.PurchaseOrderId IN (SELECT value FROM STRING_SPLIT(ISNULL(@PORerenceIds, ''), ','))) OR 
				VPOP.SalesOrderQuoteId = @ReferenceId)
			)
			SELECT @RFQPORerenceIds = STRING_AGG([ReferenceId], ',') FROM VRFQResult;

			;WITH EmailDocResult AS (
				SELECT DISTINCT VRFQ.IntegrationEmailID
				FROM [dbo].[ILSRFQPart] PT WITH(NOLOCK)
				INNER JOIN [dbo].[CustomerRfq] RFQ WITH(NOLOCK) ON PT.CustomerRfqId = RFQ.CustomerRfqId
				INNER JOIN [dbo].[VendorRFQPart] VRFQ WITH(NOLOCK) ON PT.ILSRFQDetailId = VRFQ.ILSRFQDetailId
				WHERE RFQ.ModuleId = @SOQ_ModuleId AND RFQ.ReferenceId = @ReferenceId AND VRFQ.ModuleId != @PO_ModuleId AND PT.MasterCompanyId = @MasterCompanyId
			)
			SELECT @EmailDocRerenceIds = STRING_AGG([IntegrationEmailID], ',') FROM EmailDocResult;
		END

		SELECT	cdd.DocName, 
				cdd.IsActive,
				cdd.IsDeleted, 
				ad.FileName,
				ad.FileType,
				ad.Link,
				ad.FileSize, 
				ad.AttachmentId , 
				ad.AttachmentDetailId,
				dt.Name
			FROM DBO.AttachmentDetails ad WITH(NOLOCK)
			INNER JOIN DBO.CommonDocumentDetails cdd WITH(NOLOCK) ON ad.AttachmentId = cdd.AttachmentId
			LEFT JOIN DBO.DocumentType dt WITH(NOLOCK) ON cdd.DocumentTypeId = dt.DocumentTypeId
			WHERE cdd.MasterCompanyId = @MasterCompanyId			
			AND ISNULL(cdd.IsActive,1) = 1 
			AND ISNULL(cdd.IsDeleted,0) = 0	
			AND cdd.DocumentTypeId IN (
				SELECT TRY_CAST(value AS INT)
				FROM STRING_SPLIT(
					(SELECT DocumentTypeId 
					 FROM dbo.AiIntegrationSetting WITH(NOLOCK)
					 WHERE MasterCompanyId = @MasterCompanyId), 
					','
				)
			 )
			AND ((cdd.ModuleId = @PO_DocModuleId AND cdd.ReferenceId IN (SELECT ITEM FROM dbo.SplitString(ISNULL(@PORerenceIds, ''), ',')))
			OR	(cdd.ModuleId = @VRFQPO_DocModuleId AND cdd.ReferenceId IN (SELECT ITEM FROM dbo.SplitString(ISNULL(@RFQPORerenceIds, ''), ',')))
			OR	(cdd.ModuleId = @EmailDoc_ModuleId AND cdd.ReferenceId IN (SELECT ITEM FROM dbo.SplitString(ISNULL(@EmailDocRerenceIds, ''), ',')))
			)
		
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = '[usp_GetRFQPOAndPODocumentsByReferenceId]' 
        , @ProcedureParameters VARCHAR(3000)  = ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName			= @DatabaseName
                , @AdhocComments			= @AdhocComments
                , @ProcedureParameters		= @ProcedureParameters
                , @ApplicationName			=  @ApplicationName
                , @ErrorLogID              = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
    END CATCH 
END