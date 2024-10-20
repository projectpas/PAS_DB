﻿
/*************************************************************           
 ** File:   [dbo].[usp_createAllShipVia]            
 ** Author:   Deep Patel
 ** Description: This stored procedure is used save all ship via based on type
 ** Purpose:         
 ** Date:   24/12/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:              
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    2    23/07/2024   Bhargav Saliya	Added ShippingTerms.
	3    29/07/2024   Rajesh Gami    	Check the condition AllShipViaId is already exist or not by ref.id and module Id to avoid insert the duplicate record.
     
**************************************************************/
CREATE PROCEDURE [dbo].[usp_createAllShipVia]    
(    
  @AllShipViaId bigint = 0,
  @ReferenceId bigint,
  @ModuleId bigint,        
  @UserType int,
  @ShipViaId bigint = 0,
  @ShippingCost decimal(20,3),
  @HandlingCost decimal(20,3),
  @IsModuleShipVia bit,
  @ShippingAccountNo varchar(100),
  @ShipVia varchar(100),
  @ShippingViaId bigint,
  @MasterCompanyId int,
  @CreatedBy varchar(256),
  @UpdatedBy varchar(256),
  @ShippingTerms varchar(100) = null
)    
AS    
BEGIN   
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION 
			--DECLARE @UserType NVARCHAR(50);
			--SELECT @UserType = ModuleName FROM dbo.Module WITH (NOLOCK)  WHERE ModuleId = @UserTypeId;
			DECLARE @IntertedSiteId as bigint = 0

			--IF @SiteId > 0 
			--BEGIN
			--SET @IntertedSiteId = @SiteId
			--END
			SET @AllShipViaId = (CASE WHEN @AllShipViaId = 0 THEN (SELECT TOP 1 AllShipViaId FROM DBO.AllShipVia WITH(NOLOCK) WHERE ReferenceId = @ReferenceId AND ModuleId = @ModuleId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0) ELSE @AllShipViaId END)
			IF(@AllShipViaId > 0)
			BEGIN
				UPDATE [dbo].[AllShipVia]
					SET [ReferenceId] = @ReferenceId,
						[ModuleId] = @ModuleId,
						[UserType] = @UserType,
						[ShipViaId] = @ShipViaId,
						[ShippingCost] = @ShippingCost,
						[HandlingCost] = @HandlingCost,
						[ShippingAccountNo] = @ShippingAccountNo,
						[ShipVia] = @ShipVia,
						[ShippingViaId] = @ShippingViaId,
						[MasterCompanyId] = @MasterCompanyId,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETDATE(),
						[ShippingTerms] = @ShippingTerms
					WHERE AllShipViaId = @AllShipViaId

			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[AllShipVia]
					   ([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],[ShippingAccountNo],[ShipVia]
					   ,[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted],[ShippingTerms])
				 VALUES(@ReferenceId,@ModuleId,@UserType,@ShipViaId,@ShippingCost,@HandlingCost,@IsModuleShipVia,@ShippingAccountNo,@ShipVia,
						@ShippingViaId,@MasterCompanyId,@CreatedBy,@UpdatedBy,GETDATE(),GETDATE(),1,0,@ShippingTerms)  
				SET @AllShipViaId=SCOPE_IDENTITY()		
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_createAllShipVia' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AllShipViaId, '') + ''',													   
													   @Parameter2 = ' + ISNULL(CAST(@ReferenceId AS varchar(10)) ,'') +''
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