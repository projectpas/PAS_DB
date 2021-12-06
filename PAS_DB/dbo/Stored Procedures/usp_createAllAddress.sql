

/*********************           
 ** File:   [usp_CreateAllAddress]            
 ** Author:   Deep Patel
 ** Description: This stored procedure is used save all address based on type
 ** Purpose:         
 ** Date:   24/12/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
     
 EXECUTE [USP_GetUserDetailByUserTypePOAddress] 9, '',1,'50','313'
**********************/ 
    
CREATE PROCEDURE [dbo].[usp_createAllAddress]    
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
  @ReffranceId  bigint = 0,  
  @IsModuleOnly  bit = 0,
  --@AddressType varchar(100) = 'Ship',
  @ModuleId bigint = 0,
  @IsShippingAdd bit = 0,
  @Memo varchar(500),
  @ContactId bigint = 0,
  @ContactName varchar(500),
  @Country varchar(50),
  @AllAddressId bigint = 0,
  @UserTypeName varchar(100),
  @UserName varchar(100)

)    
AS    
BEGIN   
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION 

			DECLARE @IntertedSiteId as bigint = 0
			DECLARE @ContactPhoneNo as varchar(100)
			DECLARE @WorkPhoneExtn as varchar(100)
			DECLARE @SetDesh as varchar(10)
			SELECT @WorkPhoneExtn = ISNULL(c.WorkPhoneExtn,'') FROM dbo.Contact c Where c.ContactId = @ContactId;
			IF(@WorkPhoneExtn!='')
			BEGIN
				SET @SetDesh= ' - ';
			END
			ELSE
			BEGIN
				SET @SetDesh= '';
			END
			SELECT @ContactPhoneNo = (ISNULL(c.WorkPhone,'') + @SetDesh + ISNULL(c.WorkPhoneExtn,'')) FROM dbo.Contact c Where c.ContactId = @ContactId 

			IF @SiteId > 0 
			BEGIN
			SET @IntertedSiteId = @SiteId
			END

			IF(@AllAddressId > 0)
			BEGIN
				UPDATE [dbo].[AllAddress]
					SET [ReffranceId] = @ReffranceId,
						[UserType] = @UserTypeId,
						[UserId] = @UserId,
						[SiteId] = @SiteId,
						[SiteName] = @SiteName,
						[AddressId] = @AddressId,
						[IsModuleOnly] = @IsModuleOnly,
						[IsShippingAdd] = @IsShippingAdd,
						[Memo] = @Memo,
						[ContactId] = @ContactId,
						[ContactName] = @ContactName,
						[Line1] = @Address1,
						[Line2] = @Address2,
						[Line3] = @Address3,
						[City] = @City,
						[StateOrProvince] = @StateOrProvince,
						[PostalCode] = @PostalCode,
						[CountryId] = @CountryId,
						[Country] = @Country,
						[MasterCompanyId] = @MasterCompanyId,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETDATE(),
						[UserTypeName] = @UserTypeName,
						[UserName] = @UserName,
						[ContactPhoneNo] = @ContactPhoneNo
					WHERE AllAddressId = @AllAddressId


			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[AllAddress]
					   ([ReffranceId],[ModuleId],[UserType],[UserId],[SiteId],[SiteName],[AddressId],[IsModuleOnly],[IsShippingAdd]
					   ,[Memo],[ContactId],[ContactName],[Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId]
					   ,[UserTypeName],[UserName],[Country],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted],[ContactPhoneNo])
				 VALUES(@ReffranceId,@ModuleId,@UserTypeId,@UserId,@SiteId,@SiteName,@AddressId,@IsModuleOnly,@IsShippingAdd,
						@Memo,@ContactId,@ContactName,@Address1,@Address2,@Address3,@City,@StateOrProvince,@PostalCode,@CountryId,
						@UserTypeName,@UserName,@Country,@MasterCompanyId,@CreatedBy,@UpdatedBy,GETDATE(),GETDATE(),1,0,@ContactPhoneNo)  
				SET @AllAddressId=SCOPE_IDENTITY()		
			END

			select @IntertedSiteId as IntertedSiteId

			IF @ModuleId = 13
			BEGIN 
					EXEC sp_UpdatePurchaseOrderDetail @ReffranceId
			END

			IF @ModuleId = 14
			BEGIN 
					EXEC UpdateRepairOrderDetail @ReffranceId
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_createAllAddress' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SiteId, '') + ''',													   
													   @Parameter2 = ' + ISNULL(CAST(@UserTypeId AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END