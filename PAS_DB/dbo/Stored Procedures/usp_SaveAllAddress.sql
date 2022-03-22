

/*************************************************************           
 ** File:   [usp_SaveAllAddress]           
 ** Author:   Happy Chandigara
 ** Description: This stored procedure is used save all address based on type
 ** Purpose:         
 ** Date:   01/10/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/23/2020   Happy Chandigara  Created
     
 EXECUTE [USP_GetUserDetailByUserTypePOAddress] 9, '',1,'50','313'
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[usp_SaveAllAddress]    
(    
  @SiteId bigint = 0,
  @UserTypeId bigint,
  @UserId bigint,        
  @SiteName varchar(500),
  @AddressID bigint = 0,
  @Address1 varchar(100),
  @Address2 varchar(100) = '',
  @Address3 varchar(100) = '',
  @City varchar(100),
  @StateOrProvince varchar(100),
  @PostalCode varchar(100),
  @CountryId bigint,
  @IsPrimary bit = 0,
  @MasterCompanyId bigint,
  @CreatedBy varchar(100),
  @UpdatedBy varchar(100),
  @PurchaseOrderID  bigint = 0,  
  @IsPoOnly  bit = 0,
  @AddressType varchar(100) = 'Ship' ,
  @Attention varchar(100)=''
)    
AS    
BEGIN   
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @UserType NVARCHAR(50);
		SELECT @UserType = ModuleName FROM dbo.Module WITH (NOLOCK)  WHERE ModuleId = @UserTypeId;
		DECLARE @IntertedSiteId as bigint = 0

		IF @SiteId > 0 
		BEGIN
		SET @IntertedSiteId = @SiteId
		END

		IF(@AddressID > 0)
		   BEGIN    
			UPDATE [dbo].[Address]
				   SET [Line1] = @Address1,
					   [Line2] = @Address2,
					   [Line3] = @Address3,
					   [City] = @City,
					   [StateOrProvince] = @StateOrProvince,
					   [PostalCode] = @PostalCode,
					   [CountryId] = @CountryId,
					   [MasterCompanyId] = @masterCompanyId,
					   [UpdatedBy] = @UpdatedBy,
					   UpdatedDate = GETDATE()
					WHERE AddressId = @AddressID
		   END
		   ELSE 
		   BEGIN
			INSERT INTO [dbo].[Address]
				   ([Line1],[Line2],[Line3],[City],[StateOrProvince]
				   ,[PostalCode],[CountryId],[MasterCompanyId]
				   ,[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
			 VALUES(@Address1,@Address2,@Address3,@City,@StateOrProvince,
					@PostalCode,@CountryId,@MasterCompanyId,
					@CreatedBy,@UpdatedBy,GETDATE(),GETDATE(),1,0)  
			SET @AddressID=SCOPE_IDENTITY()		
		END

		IF(@AddressType = 'Ship')  
		BEGIN
		IF(@IsPoOnly = 1)
		BEGIN
			UPDATE [dbo].POOnlyAddress
				  SET IsPrimary = 0
					 wHERE UserId = @UserId AND UserType = @UserTypeId AND PurchaseOrderId =  @PurchaseOrderID AND IsShipping = 1 AND @IsPrimary = 1
			IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].POOnlyAddress
				 SET 
					[AddressId] = @AddressID,
					[SiteName] = @SiteName,
					[MasterCompanyId] = @MasterCompanyId,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETDATE(),
					[IsPrimary] = @IsPrimary
				WHERE POOnlyAddressId = @SiteId
			END
			ELSE
			BEGIN	
			   INSERT INTO [dbo].[POOnlyAddress]
						   ([PurchaseOrderId],[UserType],[UserId]
						   ,[SiteName],[AddressId],[IsPrimary],IsShipping
						   ,[MasterCompanyId],[CreatedBy]
						   ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						 VALUES
							   (@PurchaseOrderID,@UserTypeId,@UserId
							   ,@SiteName,@AddressID,@IsPrimary,1,
							   @MasterCompanyId,@CreatedBy,
							   @UpdatedBy,GETDATE(),GETDATE(),1,0)
			SET @IntertedSiteId=SCOPE_IDENTITY()
			END
		END
		ELSE
		BEGIN
		 IF(@UserType = 'Company')
		 BEGIN 
		 UPDATE [dbo].[LegalEntityShippingAddress]
				  SET IsPrimary = 0
					 wHERE LegalEntityId = @UserId and @IsPrimary = 1

			IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].[LegalEntityShippingAddress]
			 SET [IsPrimary] = @IsPrimary,
				[AddressId] = @AddressID,
				[SiteName] = @SiteName,
				[MasterCompanyId] = @MasterCompanyId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETDATE()		
			WHERE LegalEntityShippingAddressId = @SiteId
			END
			ELSE
			BEGIN

				INSERT INTO [dbo].[LegalEntityShippingAddress]
					   ([LegalEntityId],[AddressId],[SiteName]
					   ,[IsPrimary],[MasterCompanyId],[CreatedBy]
					   ,[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted])
				 VALUES(@UserId,@AddressID,@SiteName,
						@IsPrimary,@MasterCompanyId,@CreatedBy,
						@UpdatedBy,GETDATE(),GETDATE(),
						1,0)
				SET @IntertedSiteId=SCOPE_IDENTITY()
			END

		  END

		 IF(@UserType = 'Customer')
		 BEGIN 
 			UPDATE [dbo].[CustomerDomensticShipping]
				  SET IsPrimary = 0
					 wHERE CustomerId = @UserId AND  @IsPrimary = 1
			IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].[CustomerDomensticShipping]
				SET 
				[IsPrimary] = @IsPrimary,
				[AddressId] = @AddressID,
				[SiteName] = @SiteName,
				[MasterCompanyId] = @MasterCompanyId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETDATE(),
				Attention=@Attention
				WHERE CustomerDomensticShippingId = @SiteId
			END
			ELSE
			BEGIN
	
				INSERT INTO [dbo].[CustomerDomensticShipping]
					   (CustomerId,[AddressId],[SiteName]
					   ,[IsPrimary],[MasterCompanyId],[CreatedBy]
					   ,[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted],Attention)
				 VALUES(@UserId,@AddressID,@SiteName,
						@IsPrimary,@MasterCompanyId,@CreatedBy,
						@UpdatedBy,GETDATE(),GETDATE(),
						1,0,@Attention)	
				SET @IntertedSiteId=SCOPE_IDENTITY()			
			END
		  END

		 IF(@UserType = 'Vendor')
		 BEGIN 
		 UPDATE [dbo].VendorShippingAddress
				  SET IsPrimary = 0
					 wHERE VendorId = @UserId and @IsPrimary = 1
		 IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].VendorShippingAddress
			 SET 
				[IsPrimary] = @IsPrimary,
				[AddressId] = @AddressID,
				[SiteName] = @SiteName,
				[MasterCompanyId] = @MasterCompanyId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETDATE()
			WHERE VendorShippingAddressID = @SiteId
			END
			ELSE
			BEGIN
		
				INSERT INTO [dbo].VendorShippingAddress
					   (VendorId,[AddressId],[SiteName]
					   ,[IsPrimary],[MasterCompanyId],[CreatedBy]
					   ,[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted])
				 VALUES(@UserId,@AddressID,@SiteName,
						@IsPrimary,@MasterCompanyId,@CreatedBy,
						@UpdatedBy,GETDATE(),GETDATE(),
						1,0)
				SET @IntertedSiteId=SCOPE_IDENTITY()
			END
		 END

		END
		END

		IF(@AddressType = 'Bill')  
		BEGIN
		IF(@IsPoOnly = 1)
		BEGIN
		UPDATE [dbo].POOnlyAddress
				  SET IsPrimary = 0
					 wHERE UserId = @UserId AND UserType = @UserTypeId AND PurchaseOrderId =  @PurchaseOrderID AND IsShipping = 0 AND @IsPrimary = 1
			IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].POOnlyAddress
				 SET 
					[IsPrimary] = @IsPrimary,
					[AddressId] = @AddressID,
					[SiteName] = @SiteName,
					[MasterCompanyId] = @MasterCompanyId,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETDATE()
				WHERE POOnlyAddressId = @SiteId
			END
			ELSE
			BEGIN
	
			   INSERT INTO [dbo].[POOnlyAddress]
						   ([PurchaseOrderId],[UserType],[UserId]
						   ,[SiteName],[AddressId],[IsPrimary],IsShipping
						   ,[MasterCompanyId],[CreatedBy]
						   ,[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						 VALUES
							   (@PurchaseOrderID,@UserTypeId,@UserId
							   ,@SiteName,@AddressID,@IsPrimary,0,
							   @MasterCompanyId,@CreatedBy,
							   @UpdatedBy,GETDATE(),GETDATE(),1,0)
				SET @IntertedSiteId=SCOPE_IDENTITY()
			END
		END
		ELSE
		BEGIN
		 IF(@UserType = 'Company')
		 BEGIN 
		 UPDATE [dbo].LegalEntityBillingAddress
				  SET IsPrimary = 0
					 wHERE LegalEntityId = @UserId and IsPrimary = @IsPrimary
			IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].LegalEntityBillingAddress
			 SET 
				[IsPrimary] = @IsPrimary,
				[AddressId] = @AddressID,
				[SiteName] = @SiteName,
				[MasterCompanyId] = @MasterCompanyId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETDATE()
			WHERE LegalEntityBillingAddressID = @SiteId
			END
			ELSE
			BEGIN

				INSERT INTO [dbo].LegalEntityBillingAddress
					   ([LegalEntityId],[AddressId],[SiteName]
					   ,[IsPrimary],[MasterCompanyId],[CreatedBy]
					   ,[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted])
				 VALUES(@UserId,@AddressID,@SiteName,
						@IsPrimary,@MasterCompanyId,@CreatedBy,
						@UpdatedBy,GETDATE(),GETDATE(),
						1,0)
				SET @IntertedSiteId=SCOPE_IDENTITY()
			END

		  END

		 IF(@UserType = 'Customer')
		 BEGIN 
 			UPDATE [dbo].CustomerBillingAddress
				  SET IsPrimary = 0
					 wHERE CustomerId = @UserId and IsPrimary = 1
			IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].CustomerBillingAddress
				SET 
				[IsPrimary] = @IsPrimary,
				[AddressId] = @AddressID,
				[SiteName] = @SiteName,
				[MasterCompanyId] = @MasterCompanyId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETDATE(),
				Attention=@Attention
				WHERE CustomerBillingAddressId = @SiteId
			END
			ELSE
			BEGIN
	
				INSERT INTO [dbo].CustomerBillingAddress
					   (CustomerId,[AddressId],[SiteName]
					   ,[IsPrimary],[MasterCompanyId],[CreatedBy]
					   ,[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted],Attention)
				 VALUES(@UserId,@AddressID,@SiteName,
						@IsPrimary,@MasterCompanyId,@CreatedBy,
						@UpdatedBy,GETDATE(),GETDATE(),
						1,0,@Attention)	
					SET @IntertedSiteId=SCOPE_IDENTITY()		
			END
		  END

		 IF(@UserType = 'Vendor')
		 BEGIN 
		 UPDATE [dbo].VendorBillingAddress
				  SET IsPrimary = 0
					 wHERE VendorId = @UserId AND @IsPrimary = 1
		 IF(@SiteId > 0)
			BEGIN
				UPDATE [dbo].VendorBillingAddress
			 SET 
				[IsPrimary] = @IsPrimary,
				[AddressId] = @AddressID,
				[SiteName] = @SiteName,
				[MasterCompanyId] = @MasterCompanyId,
				[UpdatedBy] = @UpdatedBy,
				[UpdatedDate] = GETDATE()
			WHERE VendorBillingAddressId = @SiteId
			END
			ELSE
			BEGIN

				INSERT INTO [dbo].VendorBillingAddress
					   (VendorId,[AddressId],[SiteName]
					   ,[IsPrimary],[MasterCompanyId],[CreatedBy]
					   ,[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted])
				 VALUES(@UserId,@AddressID,@SiteName,
						@IsPrimary,@MasterCompanyId,@CreatedBy,
						@UpdatedBy,GETDATE(),GETDATE(),
						1,0)
				SET @IntertedSiteId=SCOPE_IDENTITY()
			END
		 END

		END
	END

	SELECT @IntertedSiteId as IntertedSiteId

	COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveAllAddress' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SiteId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@UserTypeId ,'') +''
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