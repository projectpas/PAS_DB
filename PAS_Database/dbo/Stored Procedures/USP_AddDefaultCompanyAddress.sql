/*************************************************************           
 ** File:  [USP_AddDefaultCompanyAddress]          
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to store Vendor RFQ Default Address
 ** Purpose:         
 ** Date:   08/12/2025              
 ** PARAMETERS:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2025  Moin Bloch     Created
     
--    EXEC [dbo].[USP_AddDefaultCompanyAddress] 2161,31,1,'ADMIN User'
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_AddDefaultCompanyAddress]
@VendorRFQPurchaseOrderId BIGINT,
@VendorRFQPurchaseOrderModuleId INT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	

	 DECLARE @ModuleId INT = 0
	 DECLARE @UserType INT = 0,@UserTypeName VARCHAR(50)='' ,@ShipUserType INT = 0,@BillUserType INT = 0
	 DECLARE @UserId BIGINT = 0
	 DECLARE @ShipToUserName VARCHAR(100)='',@BillToUserName VARCHAR(100)=''

	 SELECT @UserType = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Company'
	 SELECT @UserTypeName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Company'
	 SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder'
		 
	 IF(@ModuleId = @VendorRFQPurchaseOrderModuleId)
	 BEGIN
		SET @ShipUserType = @UserType;
		SET @BillUserType = @UserType;
	 END	
	 
	 IF OBJECT_ID(N'tempdb..#tmpAllAddEditID') IS NOT NULL
	 BEGIN
			DROP TABLE #tmpAllAddEditID
	 END
	 IF OBJECT_ID(N'tempdb..#tmpUserShipingList') IS NOT NULL
	 BEGIN
			DROP TABLE #tmpUserShipingList
	 END
	 IF OBJECT_ID(N'tempdb..#tmpUserBillingList') IS NOT NULL
	 BEGIN
			DROP TABLE #tmpUserBillingList
	 END

	 CREATE TABLE #tmpAllAddEditID
     (    
		  [ID] BIGINT NULL,     
		  [Value] INT NULL,    
		  [Label] varchar(100) NULL	     
     )  
	 CREATE TABLE #tmpUserShipingList
     (    
		  [UserID] BIGINT NULL,     		 
		  [UserName] VARCHAR(100) NULL	    
     ) 
	 CREATE TABLE #tmpUserBillingList
     (    
		  [UserID] BIGINT NULL,     		 
		  [UserName] VARCHAR(100) NULL	        
     )  

	 INSERT INTO #tmpAllAddEditID ([ID],[Value],[Label])
	 EXEC [dbo].[usp_GetAllAddEditID] @VendorRFQPurchaseOrderId,@ModuleId
	 
	 SELECT TOP 1 @UserId = [Value] FROM #tmpAllAddEditID;

	 INSERT INTO #tmpUserShipingList ([UserID],[UserName])
	 EXEC [dbo].[USP_GetUserDetailByUserTypePOAddress] @ShipUserType,'',1,20, @UserId,@MasterCompanyId

	 INSERT INTO #tmpUserBillingList ([UserID],[UserName])
	 EXEC [dbo].[USP_GetUserDetailByUserTypePOAddress] @BillUserType,'',1,20, @UserId,@MasterCompanyId
	
	 SELECT TOP 1 @ShipToUserName = [UserName] FROM #tmpUserShipingList WHERE [UserID] = @UserId 
	 SELECT TOP 1 @BillToUserName = [UserName] FROM #tmpUserBillingList WHERE [UserID] = @UserId 
	 
	 DECLARE @billToSiteId BIGINT=0,@billToAddressId BIGINT=0
	 DECLARE @billToAddress1 VARCHAR(50)='',@billToAddress2 VARCHAR(50)='',@billToAddress3 VARCHAR(50)=''
	 DECLARE @billToCity VARCHAR(50)='',@billToStateOrProvince VARCHAR(50)=''
	 DECLARE @billToPostalCode VARCHAR(20)='',@billToCountryId BIGINT=0,@billToCountry VARCHAR(50)='' 
	 DECLARE @billToSiteName VARCHAR(256)=''
	 DECLARE @billToContactId BIGINT=0, @billToContact VARCHAR(256)='',@billToPhone VARCHAR(100)=''
	 	 
	 DECLARE @shipToSiteId BIGINT=0,@shipToAddressId BIGINT=0
	 DECLARE @shipToAddress1 VARCHAR(50)='',@shipToAddress2 VARCHAR(50)='',@shipToAddress3 VARCHAR(50)=''
	 DECLARE @shipToCity VARCHAR(50)='',@shipToStateOrProvince VARCHAR(50)=''
	 DECLARE @shipToPostalCode VARCHAR(20)='',@shipToCountryId BIGINT=0,@shipToCountry VARCHAR(50)='' 
	 DECLARE @shipToSiteName VARCHAR(256)=''
	 DECLARE @shipToContactId BIGINT=0, @shipToContact VARCHAR(256)='',@shipToPhone VARCHAR(100)=''	 	 
	 DECLARE @shippingViaId BIGINT=0,@shipViaId BIGINT=0,@ShipVia NVARCHAR(400)='',@ShippingAccountInfo VARCHAR(400)=''
	 DECLARE @LegalEntityShippingAddressId BIGINT=0, @IsPrimary BIT ,@LegalEntityShippingId BIGINT=0

	 SELECT	@billToSiteId = bad.[LegalEntityBillingAddressId]					
	   FROM [dbo].[LegalEntityBillingAddress] bad WITH(NOLOCK) 
	  WHERE bad.[LegalEntityId] = @UserId 
	    AND bad.[IsDeleted] = 0 
		AND bad.[IsActive] = 1 
		AND bad.[IsPrimary] = 1

	 SELECT	@billToAddressId = adr.[AddressId],
			@billToAddress1 = adr.[Line1],
			@billToAddress2 = adr.[Line2],
			@billToAddress3 = adr.[Line3],
			@billToCity = adr.[City],
			@billToStateOrProvince = adr.[StateOrProvince],
			@billToPostalCode = adr.[PostalCode],
			@billToCountryId = adr.[CountryId],
			@billToCountry =  c.[countries_name],			
			@billToSiteName = lsa.[SiteName]			
	  FROM [dbo].[LegalEntityBillingAddress] lsa WITH(NOLOCK) 
	 INNER JOIN [dbo].[Address] adr WITH(NOLOCK) ON lsa.[AddressId] = adr.[AddressId]
	  LEFT JOIN [dbo].[Countries] c WITH(NOLOCK) ON c.[countries_id] = adr.[CountryId]
	  WHERE lsa.[LegalEntityId] = @UserId 
		AND lsa.[IsDeleted] = 0 
		AND lsa.[IsActive] = 1 
		AND lsa.[IsPrimary] = 1
		
	 SELECT	@billToContactId = lec.[ContactId], 
			@billToContact =  co.[FirstName] + ' ' + co.[LastName],	
			@billToPhone = co.[WorkPhone] + CASE WHEN co.[WorkPhoneExtn] IS NOT NULL AND LTRIM(RTRIM(co.[WorkPhoneExtn])) <> '' THEN ' - ' + co.[WorkPhoneExtn] ELSE '' END			
		  FROM [dbo].[LegalEntityContact] lec WITH(NOLOCK) 
		  INNER JOIN [dbo].[Contact] co WITH(NOLOCK) ON co.[ContactId] = lec.[ContactId]
		  WHERE lec.[LegalEntityId] = @UserId 
		    AND lec.[IsDeleted] = 0 
		    AND lec.[IsActive] = 1 
		    AND lec.[IsDefaultContact] = 1

	 SELECT	@shipToSiteId = [LegalEntityShippingAddressId] 			
	 FROM [dbo].[LegalEntityShippingAddress] WITH(NOLOCK) 
	WHERE [LegalEntityId] = @UserId 
	  AND [IsDeleted] = 0 
	  AND [IsActive] = 1
	  AND [IsPrimary] = 1
				
	 SELECT @LegalEntityShippingAddressId = lsa.[LegalEntityShippingAddressId],
			@shipToAddressId = adr.[AddressId],
			@shipToAddress1 = adr.[Line1],
			@shipToAddress2 = adr.[Line2],
			@shipToAddress3 = adr.[Line3],
			@shipToCity = adr.[City],
			@shipToStateOrProvince = adr.[StateOrProvince],
			@shipToPostalCode = adr.[PostalCode],
			@shipToCountryId = adr.[CountryId],
			@shipToCountry=  c.[countries_name],			
			@shipToSiteName = lsa.[SiteName]			
	   FROM [dbo].[LegalEntityShippingAddress] lsa WITH(NOLOCK) 
	 INNER JOIN [dbo].[Address] adr WITH(NOLOCK) ON lsa.[AddressId] = adr.[AddressId]
	  LEFT JOIN [dbo].[Countries] c WITH(NOLOCK) ON c.[countries_id] = adr.[CountryId]
	  WHERE lsa.[LegalEntityId] = @UserId 
	    AND lsa.[IsDeleted] = 0 
		AND lsa.[IsActive] = 1
		AND lsa.[IsPrimary] = 1
				
	 SELECT @shipToContactId = lec.[ContactId],
			 @shipToContact = co.[FirstName] + ' ' + co.[LastName], 
			 @shipToPhone = co.[WorkPhone] + CASE WHEN co.[WorkPhoneExtn] IS NOT NULL AND LTRIM(RTRIM(co.[WorkPhoneExtn])) <> '' THEN ' - ' + co.[WorkPhoneExtn] ELSE '' END			
		FROM [dbo].[LegalEntityContact] lec WITH(NOLOCK) 
		INNER JOIN [dbo].[Contact] co WITH(NOLOCK) ON co.[ContactId] = lec.[ContactId]
		WHERE [LegalEntityId] = @UserId 
		AND lec.[IsDeleted] = 0 
		AND lec.[IsActive] = 1
		AND lec.[IsDefaultContact] = 1	
		
	SELECT	@LegalEntityShippingId = lec.LegalEntityShippingId
		FROM [dbo].[LegalEntityShipping] lec WITH(NOLOCK) 
		INNER JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON sv.[ShippingViaId] = lec.[ShipViaId]
		 LEFT JOIN [dbo].[ShippingTerms] ST WITH(NOLOCK) ON ST.ShippingTermsId = lec.ShippingTermsId
		 WHERE lec.[LegalEntityId] = @UserId 
		AND lec.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId
		AND lec.[IsDeleted] = 0 
		AND lec.[IsActive] = 1
		AND lec.[IsPrimary] = 1

	IF (@LegalEntityShippingId > 0)
	BEGIN
		 SELECT @ShippingViaId = lec.[LegalEntityShippingId],
				@ShipVia = sv.[Name],
				@ShippingAccountInfo = lec.[ShippingAccountinfo],
				@ShipViaId = sv.[ShippingViaId],	
				@IsPrimary = lec.[IsPrimary]
			FROM [dbo].[LegalEntityShipping] lec WITH(NOLOCK) 
			INNER JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON sv.[ShippingViaId] = lec.[ShipViaId]
			 LEFT JOIN [dbo].[ShippingTerms] ST WITH(NOLOCK) ON ST.ShippingTermsId = lec.ShippingTermsId
			 WHERE lec.[LegalEntityId] = @UserId 
			AND lec.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId
			AND lec.[IsDeleted] = 0 
			AND lec.[IsActive] = 1
			AND lec.[IsPrimary] = 1
	END
	ELSE
	BEGIN
		 SELECT TOP 1 @ShippingViaId = lec.[LegalEntityShippingId],
				@ShipVia = sv.[Name],
				@ShippingAccountInfo = lec.[ShippingAccountinfo],
				@ShipViaId = sv.[ShippingViaId],	
				@IsPrimary = lec.[IsPrimary]
			FROM [dbo].[LegalEntityShipping] lec WITH(NOLOCK) 
			INNER JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON sv.[ShippingViaId] = lec.[ShipViaId]
			 LEFT JOIN [dbo].[ShippingTerms] ST WITH(NOLOCK) ON ST.ShippingTermsId = lec.ShippingTermsId
			 WHERE lec.[LegalEntityId] = @UserId 
			AND lec.[LegalEntityShippingAddressId] = @LegalEntityShippingAddressId
			AND lec.[IsDeleted] = 0 
			AND lec.[IsActive] = 1		
	END		
   
     IF NOT EXISTS (SELECT 1 FROM [dbo].[AllAddress] WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQPurchaseOrderId AND [ModuleId] = @ModuleId)    
     BEGIN 
	 			-- SHIP TO ADDRESS		 
		 INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
			     [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
			     [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],
				 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
          SELECT @VendorRFQPurchaseOrderId,@ModuleId,@UserType,UPPER(@UserTypeName),@UserId,UPPER(@ShipToUserName),@shipToSiteId,UPPER(@shipToSiteName),
				 @shipToAddressId,0,1,NULL,'',@shipToContactId,UPPER(@shipToContact),@shipToPhone,
				 @shipToAddress1,@shipToAddress2,@shipToAddress3,UPPER(@shipToCity),UPPER(@shipToStateOrProvince),@shipToPostalCode,@shipToCountryId,UPPER(@shipToCountry),@MasterCompanyId,
				 @CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0

		    -- BILL TO ADDRESS 	
         INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],    
			     [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],    
			     [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],
				 [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])    
          SELECT @VendorRFQPurchaseOrderId,@ModuleId,@UserType,UPPER(@UserTypeName),@UserId,UPPER(@BillToUserName),@billToSiteId,UPPER(@billToSiteName),
		         @billToAddressId,0,0,NULL,'',@billToContactId,UPPER(@billToContact),@billToPhone,
				 @billToAddress1,@billToAddress2,@billToAddress3,UPPER(@billToCity),UPPER(@billToStateOrProvince),@billToPostalCode,@billToCountryId,UPPER(@billToCountry),@MasterCompanyId,
		  	     @CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0
         
			 -- SHIP VIA
		 IF(@ShippingViaId > 0)
		 BEGIN		 
			 INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
			   [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate] ,[UpdatedDate],[IsActive] ,[IsDeleted])    
			 SELECT @VendorRFQPurchaseOrderId,@ModuleId,@UserType,@ShipViaId,0,0,0,
					@ShippingAccountInfo,@ShipVia,@ShippingViaId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0
		 END
		 ELSE
		 BEGIN
			IF NOT EXISTS(SELECT 1 FROM [dbo].[ShippingVia] WITH(NOLOCK) WHERE [Name]='NA' AND [MasterCompanyId]=@MasterCompanyId)
			BEGIN
				INSERT INTO [dbo].[ShippingVia]([Name],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Description],[CarrierId])
				                         SELECT 'NA','',@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,NULL,NULL   
										 
				SET @ShipViaId = SCOPE_IDENTITY();	
				
				INSERT INTO [dbo].[LegalEntityShipping]([LegalEntityId],[LegalEntityShippingAddressId],[ShipVia],[ShippingAccountInfo],[Memo],[MasterCompanyId]
						   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary],[ShipViaId],[ShippingTermsId])
					 SELECT @UserId,@LegalEntityShippingAddressId,'NA','NA','',@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0,@ShipViaId,NULL	
				
				SET @ShippingViaId = SCOPE_IDENTITY();		

				INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],    
					[ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate] ,[UpdatedDate],[IsActive] ,[IsDeleted])    
				SELECT @VendorRFQPurchaseOrderId,@ModuleId,@UserType,@ShipViaId,0,0,0,
					'NA','NA',@ShippingViaId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0	
					
			END
		 END
     END 
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddDefaultCompanyAddress' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQPurchaseOrderId, '') AS varchar(100))			                                        													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END