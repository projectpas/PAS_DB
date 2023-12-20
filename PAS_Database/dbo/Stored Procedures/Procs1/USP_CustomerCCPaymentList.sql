/********************************************************************
 ** File:   [USP_CustomerCCPaymentList]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used get the list of CustomerCCPayment
 ** Purpose:         
 ** Date:   09/01/2023  
          
 ** PARAMETERS:  
     
 ***********************************************************************    
 ** Change History           
 *********************************************************************** 
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			------------------------------------
    1    09/01/2023   Devendra Shekh		    Created

exec USP_CustomerCCPaymentList     
@PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@LegalEntity=0,@CustomerName=N'fs',@CompanyBankAccount=NULL,@MerchantID=NULL,@CreatedBy=NULL
,@CreatedDate='2023-08-24 17:41:21.587',@UpdatedBy=NULL,@UpdatedDate='2023-08-24 17:41:21.587',@MasterCompanyId=1,@IsActive=null,@IsDeleted=null
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CustomerCCPaymentList] 
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',	
	@LegalEntity varchar(100) = NULL,
	@CustomerName varchar(100) = NULL,
	@CompanyBankAccount varchar(100) = NULL,
	@MerchantID varchar(100) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@MasterCompanyId bigint = NULL,
	@StatusId int = NULL,
	@IsDeleted bit = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @Count Int;
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
			SET @SortOrder = -1
		END 
		ELSE
		BEGIN 
			Set @SortColumn = Upper(@SortColumn)
		END
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END

		;WITH Result AS (	
			SELECT DISTINCT
				LT.CustomerCCPaymentsId
			   ,LD.Name as 'LegalEntity'
			   ,LT.CustomerName
			   ,LT.MerchantID
			   ,S.BankName + '-' + S.BankAccountNumber as 'CompanyBankAccount'
			   ,LT.[MasterCompanyId]
			   ,LT.[CreatedBy]
			   ,LT.[UpdatedBy]
			   ,LT.[CreatedDate]
			   ,LT.[UpdatedDate]
			   ,LT.[IsActive]
			   ,LT.[IsDeleted]
				FROM [dbo].[CustomerCCPayments] LT WITH(NOLOCK) 
				INNER JOIN dbo.LegalEntity LD WITH(NOLOCK) on LT.LegalEntityId = LD.LegalEntityId
				INNER JOIN [dbo].[LegalEntityBankingLockBox] S WITH(NOLOCK) ON LT.CompanyBankAccount = S.LegalEntityBankingLockBoxId
 			WHERE LT.IsDeleted = @IsDeleted AND (@IsActive IS NULL OR LT.IsActive=@IsActive) And LT.MasterCompanyId = @MasterCompanyId
		  	) , ResultCount AS(Select COUNT(CustomerCCPaymentsId) AS totalItems FROM Result) 
		SELECT * INTO #TempResult FROM  Result
			 WHERE ((ISNULL(@GlobalFilter,'') <>'' AND ((LegalEntity LIKE '%' +@GlobalFilter+'%') OR
			        (CustomerName LIKE '%' +@GlobalFilter+'%') OR	
					(MerchantID LIKE '%' +@GlobalFilter+'%') OR
					(CompanyBankAccount LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(ISNULL(@GlobalFilter,'')='' AND (ISNULL(@LegalEntity,'') ='' OR LegalEntity LIKE '%' + @LegalEntity+'%') AND
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND	
					(ISNULL(@MerchantID,'') ='' OR MerchantID LIKE '%' + @MerchantID + '%') AND	
					(ISNULL(@CompanyBankAccount,'') ='' OR CompanyBankAccount LIKE '%' + @CompanyBankAccount + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(CustomerCCPaymentsId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='LegalEntity')  THEN LegalEntity END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LegalEntity')  THEN LegalEntity END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MerchantID')  THEN MerchantID END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MerchantID')  THEN MerchantID END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyBankAccount')  THEN CompanyBankAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyBankAccount')  THEN CompanyBankAccount END DESC,			
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_CustomerCCPaymentList]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END