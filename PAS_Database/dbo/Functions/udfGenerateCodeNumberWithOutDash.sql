  
CREATE   FUNCTION [dbo].[udfGenerateCodeNumberWithOutDash]    
(    
   @Input BIGINT,    
   @prefix NVARCHAR(50),    
   @suffix NVARCHAR(50)  
)    
RETURNS @Output TABLE (    
   StocklineNumber NVARCHAR(50)    
)    
AS    
BEGIN    
DECLARE @code NVARCHAR(50), @numLength INT    
  
SELECT @numLength = LEN(@Input);  
  
IF(@numLength = 1)  
BEGIN  
 IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(@prefix,'00000' + CAST(@Input AS VARCHAR(50)), @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') = '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT('00000' + CAST(@Input AS VARCHAR(50)), @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') = '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '00000' + CAST(@Input AS VARCHAR(50)))  
 END  
 ELSE   
 BEGIN  
  SET @code = '00000' + CAST(@Input AS VARCHAR(50))  
 END  
END  
  
IF(@numLength = 2)  
BEGIN  
 IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '0000' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') = '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT('0000' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') = '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '0000' + CAST(@Input AS VARCHAR(50)))  
 END  
 ELSE   
 BEGIN  
  SET @code = '0000' + CAST(@Input AS VARCHAR(50))  
 END  
END  
  
IF(@numLength = 3)  
BEGIN  
 IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '000' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') = '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT('000' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') = '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '000' + CAST(@Input AS VARCHAR(50)))  
 END  
 ELSE   
 BEGIN  
  SET @code = '000' + CAST(@Input AS VARCHAR(50))  
 END  
END  
  
IF(@numLength = 4)  
BEGIN  
 IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '00' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') = '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT('00' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') = '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '00' + CAST(@Input AS VARCHAR(50)))  
 END  
 ELSE   
 BEGIN  
  SET @code = '00' + CAST(@Input AS VARCHAR(50))  
 END  
END  
  
IF(@numLength = 5)  
BEGIN  
 IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '0' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') = '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT('0' + CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') = '')  
 BEGIN  
  SET @code = CONCAT(@prefix, '0' + CAST(@Input AS VARCHAR(50)))  
 END  
 ELSE   
 BEGIN  
  SET @code = '0' + CAST(@Input AS VARCHAR(50))  
 END  
END  
  
IF(@numLength > 5)  
BEGIN  
 IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(@prefix,  CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') = '' AND COALESCE(@suffix,'') <> '')  
 BEGIN  
  SET @code = CONCAT(CAST(@Input AS VARCHAR(50)) , @suffix )  
 END  
 ELSE IF (COALESCE(@prefix, '') <> '' AND COALESCE(@suffix,'') = '')  
 BEGIN  
  SET @code = CONCAT(@prefix,  CAST(@Input AS VARCHAR(50)))  
 END  
 ELSE   
 BEGIN  
  SET @code = CAST(@Input AS VARCHAR(50))  
 END  
END  
  
INSERT INTO @Output(StocklineNumber)    
SELECT @code    
RETURN    
END