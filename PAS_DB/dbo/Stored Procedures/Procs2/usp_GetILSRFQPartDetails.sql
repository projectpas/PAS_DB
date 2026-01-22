/*************************************************************
 ** File:  [usp_GetILSRFQPartDetails] 
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get the ILS RFQ Part For Print 
 ** Date:  15-Dec-2025
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    15-Dec-2025		Devendra Shekh		  Created

EXEC [dbo].[usp_GetILSRFQPartDetails] '182', 2, 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_GetILSRFQPartDetails] (
	@ILSRFQPartIds VARCHAR(MAX) = NULL,
	@EmployeeId BIGINT = NULL,
	@MasterCompanyId INT = NULL
)
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   
	BEGIN TRY
	BEGIN

		DECLARE @BuyerEmail VARCHAR(200);

		IF OBJECT_ID('tempdb..#tmpILSRFQParts') IS NOT NULL
		BEGIN
			DROP TABLE #tmpILSRFQParts
		END

		IF OBJECT_ID('tempdb..#tmpILSRFQ') IS NOT NULL
		BEGIN
			DROP TABLE #tmpILSRFQ
		END

		IF OBJECT_ID('tempdb..#tmpVendor') IS NOT NULL
		BEGIN
			DROP TABLE #tmpVendor
		END

		CREATE TABLE #tmpILSRFQParts (
			[ILSRFQPartId] [bigint] NULL,
			[ILSRFQDetailId] [bigint] NULL,
			[PartNumber] [varchar](70) NULL,
			[AltPartNumber] [varchar](70) NULL,
			[Exchange] [varchar](70) NULL,
			[Description] [varchar](max) NULL,
			[Qty] [int] NULL,
			[RequestedQty] [int] NULL,
			[Condition] [varchar](20) NULL,
			[IsEmail] [bit] NULL,
			[IsFax] [bit] NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](256) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2] NULL,
			[UpdatedDate] [datetime2] NULL,
			[IsDeleted] [bit] NULL,
			[IsActive] [bit] NULL,
			[VendorName] [varchar](150) NULL,
			[CustomerRfqId] [bigint] NULL,
			[VendorId] [bigint] NULL,
			[Address1] [varchar](250) NULL,
			[Address2] [varchar](250) NULL,
			[City] [varchar](50) NULL,
			[StateProvince] [varchar](50) NULL,
			[PostalCode] [varchar](50) NULL,
			[Country] [varchar](50) NULL,
		)

		CREATE TABLE #tmpILSRFQ (
			[ThirdPartyRFQId] [bigint] NULL,
			[RFQId] [varchar](50) NULL,
			[PortalRFQId] [varchar](50) NULL,
			[Name] [varchar](100) NULL,
			[IntegrationRFQTypeId] [int] NULL,
			[TypeName] [varchar](50) NULL,
			[IntegrationPortalId] [int] NULL,
			[IntegrationPortal] [varchar](50) NULL,
			[IntegrationRFQStatusId] [int] NULL,
			[Status] [varchar](20) NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](256) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2](7) NULL,
			[UpdatedDate] [datetime2](7) NULL,
			[IsDeleted] [bit] NULL,
			[IsActive] [bit] NULL,
			[ILSRFQDetailId] [bigint] NULL,
			[PriorityId] [int] NULL,
			[Priority] [varchar](50) NULL,
			[RequestedQty] [int] NULL,
			[QuoteWithinDays] [int] NULL,
			[DeliverByDate] [datetime2](7) NULL,
			[PreparedBy] [varchar](50) NULL,
			[AttachmentId] [bigint] NULL,
			[DeliverToAddress] [nvarchar](max) NULL,
			[BuyerComment] [nvarchar](max) NULL,
			[PriceType] [varchar](50) NULL,
			[VendorName] [varchar](250) NULL,
			[VendorCode] [varchar](250) NULL,
			[VendorContact] [varchar](250) NULL,
			[CreditTerm] [varchar](250) NULL,
			[BuyerEmail] [varchar](250) NULL,
			[VendorRFQDate] [varchar](250) NULL,
		)

		/* --------------START: Get the timzone and UTC offset -------------- */
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(400) = '', @BaseUtcOffsetSec BIGINT = 0;
		SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
		FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId AND E.MasterCompanyId = @MasterCompanyId;	
				
		SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
		/* -------------- END: Get the timzone and UTC offset -------------- */

		--SELECT @BuyerEmail = [Email] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId;

		INSERT INTO #tmpILSRFQParts
		SELECT	ILSRFQPartId, ILSRFQDetailId, PartNumber, AltPartNumber, Exchange, Description, Qty, RequestedQty, Condition, IsEmail, IsFax, MasterCompanyId, 
				CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsDeleted, IsActive, VendorName, CustomerRfqId, 0, [Address1], [Address2], [City], [StateProvince], [PostalCode], [Country] 
		FROM [dbo].[ILSRFQPart] ILS WITH(NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId AND ILS.ILSRFQPartId IN (SELECT value FROM STRING_SPLIT(@ILSRFQPartIds, ','))

		UPDATE TMP
		SET	TMP.VendorId = V.VendorId
		FROM #tmpILSRFQParts TMP
		INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON UPPER(TRIM(TMP.VendorName)) = UPPER(TRIM(V.VendorName)) AND V.MasterCompanyId = @MasterCompanyId

		INSERT INTO #tmpILSRFQ 
		(	[ThirdPartyRFQId], [RFQId], [PortalRFQId], [Name], [IntegrationRFQTypeId], [TypeName], [IntegrationPortalId], [IntegrationPortal], [IntegrationRFQStatusId], [Status], [MasterCompanyId],
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsDeleted], [IsActive], [ILSRFQDetailId], [PriorityId], [Priority], [RequestedQty], [QuoteWithinDays], [DeliverByDate], [PreparedBy],
			[AttachmentId], [DeliverToAddress], [BuyerComment], [PriceType]
		)
		SELECT	TPR.[ThirdPartyRFQId], [RFQId], [PortalRFQId], [Name], [IntegrationRFQTypeId], [TypeName], [IntegrationPortalId], [IntegrationPortal], [IntegrationRFQStatusId], [Status],
				TPR.[MasterCompanyId], TPR.[CreatedBy], TPR.[UpdatedBy], TPR.[CreatedDate], TPR.[UpdatedDate], TPR.[IsDeleted], TPR.[IsActive], [ILSRFQDetailId], [PriorityId], [Priority],
				[RequestedQty], [QuoteWithinDays], [DeliverByDate], [PreparedBy], [AttachmentId], [DeliverToAddress], [BuyerComment], [PriceType]
		FROM [dbo].[ThirdPartyRFQ] TPR WITH(NOLOCK)
		INNER JOIN [dbo].[ILSRFQDetail] RFD WITH(NOLOCK) ON TPR.ThirdPartyRFQId = RFD.ThirdPartyRFQId
		WHERE RFD.ILSRFQDetailId IN (SELECT TOP 1 ILSRFQDetailId FROM #tmpILSRFQParts);

		UPDATE TMP
		SET	TMP.VendorName = ISNULL(Result.VendorName, ''),
			TMP.VendorCode = ISNULL(Result.VendorCode, ''),
			TMP.VendorContact =  ISNULL(Result.VendorContact, ''),
			TMP.CreditTerm = ISNULL(Result.[Name], ''),
			TMP.BuyerEmail = ISNULL(Result.Email, ''),
			TMP.VendorRFQDate = CONVERT(datetime2,DATEADD(SECOND, @BaseUtcOffsetSec, TMP.CreatedDate))
		FROM #tmpILSRFQ TMP
		OUTER APPLY (
			SELECT DISTINCT
				V.VendorName, V.VendorCode, CONCAT(ISNULL(C.FirstName, ''), ' ', ISNULL(C.LastName, '')) VendorContact, CT.[Name], C.Email
			FROM #tmpILSRFQParts tmpPart
			INNER JOIN [dbo].[Vendor] V WITH(NOLOCK) ON tmpPart.VendorId = V.VendorId
			LEFT JOIN [dbo].[VendorContact] VC WITH(NOLOCK) ON V.VendorId = VC.VendorId
			LEFT JOIN [dbo].[Contact] C WITH (NOLOCK) ON VC.ContactId = C.ContactId
			LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON V.CreditTermsId = CT.CreditTermsId
			WHERE TMP.ILSRFQDetailId = tmpPart.ILSRFQDetailId
		) Result

		SELECT	[ThirdPartyRFQId], [RFQId], [PortalRFQId], [Name], [IntegrationRFQTypeId], [TypeName], [IntegrationPortalId], [IntegrationPortal], [IntegrationRFQStatusId], [Status], [MasterCompanyId],
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsDeleted], [IsActive], [ILSRFQDetailId], [PriorityId], [Priority], [RequestedQty], [QuoteWithinDays], [DeliverByDate], [PreparedBy],
				[AttachmentId], [DeliverToAddress], [BuyerComment], [PriceType], [VendorName], [VendorCode], [VendorContact], [CreditTerm], [BuyerEmail], [VendorRFQDate]
		FROM #tmpILSRFQ;

		SELECT	[ILSRFQPartId], [ILSRFQDetailId], [PartNumber], [AltPartNumber], [Exchange], [Description], [Qty], [RequestedQty], [Condition], [IsEmail], [IsFax], [MasterCompanyId],
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsDeleted], [IsActive], [VendorName], [CustomerRfqId], [VendorId], [Address1], [Address2], [City], [StateProvince], [PostalCode], [Country]
		FROM #tmpILSRFQParts;
	END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'usp_getEmailTemplates_byTemplateType' 
			, @ProcedureParameters VARCHAR(3000)  = ''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName				= @DatabaseName
			, @AdhocComments			= @AdhocComments
			, @ProcedureParameters		= @ProcedureParameters
			, @ApplicationName			= @ApplicationName
			, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END